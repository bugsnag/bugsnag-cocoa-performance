//
//  BugsnagPerformanceImpl.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 15.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "BugsnagPerformanceImpl.h"

#import "BSGInternalConfig.h"
#import "OtlpTraceEncoding.h"
#import "ResourceAttributes.h"
#import "Utils.h"

using namespace bugsnag;

static double initialProbability = 1.0;

static NSString *getPersistenceDir() {
    // Persistent data in bugsnag-performance can handle files disappearing, so put it in the caches dir.
    // Namespace it to the bundle identifier because all MacOS non-sandboxed apps share the same cache dir.
    NSString *cachesDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *topDir = [NSString stringWithFormat:@"bugsnag-performance-%@", [[NSBundle mainBundle] bundleIdentifier]];
    return [cachesDir stringByAppendingPathComponent:topDir];
}

BugsnagPerformanceImpl::BugsnagPerformanceImpl() noexcept
: batch_(std::make_shared<Batch>())
, sampler_(std::make_shared<Sampler>(initialProbability))
, tracer_(sampler_, batch_)
, persistence_(std::make_shared<Persistence>(getPersistenceDir()))
{}

bool BugsnagPerformanceImpl::start(BugsnagPerformanceConfiguration *configuration, NSError **error) noexcept {
    {
        std::lock_guard<std::mutex> guard(mutex_);
        if (started_) {
            return true;
        }
        started_ = true;
    }

    if (![configuration validate:error]) {
        return false;
    }

    /* Note: Be careful about initialization order!
     *
     * - Everything depends on persistence at some level
     * - uploader depends on resourceAttributes and sampler
     * - persistentState depends on persistence and will call on worker later
     * - worker depends on uploader and sampler
     * - batch depends on worker
     * - tracer depends on sampler and batch
     * - Reachability depends on worker
     */

    __block auto blockThis = this;
    NSError *__autoreleasing concreteError = nil;
    if (error == nil) {
        error = &concreteError;
    }
    *error = nil;

    resourceAttributes_ = ResourceAttributes(configuration).get();

    if ((*error = persistence_->start()) != nil) {
        BSGLogError(@"error while starting persistence: %@", *error);
        return false;
    }

    retryQueue_ = std::make_unique<RetryQueue>([persistence_->topLevelDirectory() stringByAppendingPathComponent:@"retry-queue"]);
    retryQueue_->setOnFilesystemError(^{
        blockThis->onFilesystemError();
    });

    sampler_->setFallbackProbability(configuration.samplingProbability);

    uploader_ = std::make_shared<OtlpUploader>(configuration.endpoint,
                                                   configuration.apiKey,
                                                   ^(double newProbability) {
        blockThis->onProbabilityChanged(newProbability);
    });

    auto persistentStateFile = [persistence_->topLevelDirectory() stringByAppendingPathComponent:@"persistent-state.json"];
    persistentState_ = std::make_shared<PersistentState>(persistentStateFile, ^void() {
        blockThis->onPersistentStateChanged();
    });

    worker_ = [[Worker alloc] initWithInitialTasks:buildInitialTasks()
                                    recurringTasks:buildRecurringTasks()
                                      workInterval:bsgp_performWorkInterval];
    [worker_ start];

    batch_->setBatchFullCallback(^{
        blockThis->onBatchFull();
    });

    tracer_.start(configuration);

    Reachability::get().addCallback(^(Reachability::Connectivity connectivity) {
        blockThis->onConnectivityChanged(connectivity);
    });

    return true;
}

#pragma mark Tasks

NSArray<Task> *BugsnagPerformanceImpl::buildInitialTasks() {
    __block auto blockThis = this;
    return @[
        ^bool() { return blockThis->sendPValueRequestTask(); },
    ];
}

NSArray<Task> *BugsnagPerformanceImpl::buildRecurringTasks() {
    __block auto blockThis = this;
    return @[
        ^bool() { return blockThis->maybePersistStateTask(); },
        ^bool() { return blockThis->sendCurrentBatchTask(); },
        ^bool() { return blockThis->sendRetriesTask(); },
    ];
}

bool BugsnagPerformanceImpl::sendPValueRequestTask() {
    uploader_->upload(*OtlpTraceEncoding::buildPValueRequestPackage(), nil);
    return true;
}

bool BugsnagPerformanceImpl::sendCurrentBatchTask() {
    auto spans = sampler_->sampled(batch_->drain());
    if (spans->size() == 0) {
        return false;
    }

    uploadPackage(OtlpTraceEncoding::buildUploadPackage(*spans, resourceAttributes_), false);
    return true;
}

bool BugsnagPerformanceImpl::sendRetriesTask() {
    retryQueue_->sweep();

    auto retries = retryQueue_->list();
    if (retries.size() == 0) {
        return false;
    }

    for (auto &&timestamp: retries) {
        auto retry = retryQueue_->get(timestamp);
        if (retry != nullptr) {
            uploadPackage(std::move(retry), true);
        }
    }

    // Retries never count as work, otherwise we'd loop endlessly on a network outage.
    return false;
}

bool BugsnagPerformanceImpl::maybePersistStateTask() {
    if (shouldPersistState_) {
        auto error = persistentState_->persist();
        if (error != nil) {
            BSGLogError(@"error while persisting state: %@", error);
            onFilesystemError();
        }
        return true;
    }
    return false;
}

#pragma mark Event Reactions

void BugsnagPerformanceImpl::onFilesystemError() noexcept {
    persistence_->clear();
}

void BugsnagPerformanceImpl::onBatchFull() noexcept {
    wakeWorker();
}

void BugsnagPerformanceImpl::onConnectivityChanged(Reachability::Connectivity connectivity) noexcept {
    switch (connectivity) {
        case Reachability::Cellular: case Reachability::Wifi:
            wakeWorker();
            break;
        case Reachability::Unknown: case Reachability::None:
            // Don't care
            break;
    }
}

void BugsnagPerformanceImpl::onProbabilityChanged(double newProbability) noexcept {
    sampler_->setProbability(newProbability);
    persistentState_->setProbability(newProbability);
}

void BugsnagPerformanceImpl::onPersistentStateChanged() noexcept {
    shouldPersistState_ = true;
    wakeWorker();
}

#pragma mark Utility

void BugsnagPerformanceImpl::wakeWorker() noexcept {
    [worker_ wake];
}

void BugsnagPerformanceImpl::uploadPackage(std::unique_ptr<OtlpPackage> package, bool isRetry) noexcept {
    if (package == nullptr) {
        return;
    }

    // Give up waiting for the upload after 20 seconds
    NSTimeInterval maxWaitInterval = 20.0;

    __block auto blockThis = this;
    __block std::unique_ptr<OtlpPackage> blockPackage = std::move(package);
    __block auto condition = [NSCondition new];

    [condition lock];
    uploader_->upload(*blockPackage, ^(UploadResult result) {
        switch (result) {
            case UploadResult::SUCCESSFUL:
                if (isRetry) {
                    blockThis->retryQueue_->remove(blockPackage->timestamp);
                }
                break;
            case UploadResult::FAILED_CAN_RETRY:
                if (!isRetry) {
                    blockThis->retryQueue_->add(*blockPackage);
                }
                break;
            case UploadResult::FAILED_CANNOT_RETRY:
                // We can't do anything with it, so throw it out.
                if (isRetry) {
                    blockThis->retryQueue_->remove(blockPackage->timestamp);
                }
                break;
        }
        [condition lock];
        [condition signal];
        [condition unlock];
    });
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:maxWaitInterval];
    [condition waitUntilDate:timeoutDate];
    [condition unlock];
}
