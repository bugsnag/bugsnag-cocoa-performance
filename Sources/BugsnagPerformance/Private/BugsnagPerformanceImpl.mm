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
        NSLog(@"BugsnagPerformance: Error starting persistence: %@", *error);
        return false;
    }

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
        ^bool() { return blockThis->sendInitialPValueRequestTask(); },
    ];
}

NSArray<Task> *BugsnagPerformanceImpl::buildRecurringTasks() {
    __block auto blockThis = this;
    return @[
        ^bool() { return blockThis->sendCurrentBatchAndRetriesTask(); },
        ^bool() { return blockThis->maybePersistStateTask(); },
    ];
}

bool BugsnagPerformanceImpl::sendInitialPValueRequestTask() {
    auto emptyPayload = [@"{\"resourceSpans\": []}" dataUsingEncoding:NSUTF8StringEncoding];
    auto emptyPackage = OtlpPackage(emptyPayload, @{});
    uploader_->upload(emptyPackage, nil);
    return true;
}

bool BugsnagPerformanceImpl::sendCurrentBatchAndRetriesTask() {
    if (retryQueue_.size() == 0) {
        return sendCurrentBatchTask();
    }

    // save retries before sending the current batch
    auto retries = std::move(retryQueue_);
    retryQueue_ = std::vector<std::unique_ptr<OtlpPackage>>();

    // We don't care about this result because we already know there is retry work to be done.
    sendCurrentBatchTask();
    
    for (size_t i = 0; i < retries.size(); i++) {
        uploadPackage(std::move(retries[i]));
    }

    return true;
}

bool BugsnagPerformanceImpl::sendCurrentBatchTask() {
    auto spans = sampler_->sampled(batch_->drain());

    if (spans->size() > 0) {
        uploadPackage(buildPackage(*spans));
        return true;
    }
    return false;
}

bool BugsnagPerformanceImpl::maybePersistStateTask() {
    if (shouldPersistState_) {
        auto error = persistentState_->persist();
        if (error != nil) {
            NSLog(@"BugsnagPerformance: Error persisting state: %@", error);
            persistence_->clear();
        }
        return true;
    }
    return false;
}

#pragma mark Event Reactions

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

void BugsnagPerformanceImpl::queueRetry(std::unique_ptr<OtlpPackage> package) noexcept {
    retryQueue_.push_back(std::move(package));
}

void BugsnagPerformanceImpl::uploadPackage(std::unique_ptr<OtlpPackage> package) noexcept {
    if (package == nullptr) {
        return;
    }
    
    __block auto blockThis = this;
    __block std::unique_ptr<OtlpPackage> blockPackage = std::move(package);

    uploader_->upload(*blockPackage, ^(UploadResult result) {
        switch (result) {
            case UploadResult::SUCCESSFUL:
                break;
            case UploadResult::FAILED_CAN_RETRY:
                blockThis->queueRetry(std::move(blockPackage));
                break;
            case UploadResult::FAILED_CANNOT_RETRY:
                // We can't do anything with it, so throw it out.
                break;
        }
    });
}

std::unique_ptr<OtlpPackage> BugsnagPerformanceImpl::buildPackage(const std::vector<std::unique_ptr<SpanData>> &spans) const noexcept {
    return OtlpTraceEncoding::buildUploadPackage(spans, resourceAttributes_);
}
