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

void (^generateOnSpanStarted(BugsnagPerformanceImpl *impl))(void) {
    __block auto blockImpl = impl;
  return ^{
      blockImpl->onSpanStarted();
  };
}

BugsnagPerformanceImpl::BugsnagPerformanceImpl() noexcept
: batch_(std::make_shared<Batch>())
, sampler_(std::make_shared<Sampler>(initialProbability))
, tracer_(sampler_, batch_, generateOnSpanStarted(this))
, persistence_(std::make_shared<Persistence>(getPersistenceDir()))
, appStateTracker_([AppStateTracker new])
, viewControllersToSpans_([NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory | NSMapTableObjectPointerPersonality
                                                valueOptions:NSMapTableStrongMemory])
{}

void BugsnagPerformanceImpl::start(BugsnagPerformanceConfiguration *configuration) noexcept {
    {
        std::lock_guard<std::mutex> guard(instanceMutex_);
        if (started_) {
            return;
        }
        started_ = true;
    }
    
    NSError *__autoreleasing error = nil;

    if (![configuration validate:&error]) {
        BSGLogError(@"Configuration validation failed with error: %@", error);
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

    resourceAttributes_ = ResourceAttributes(configuration).get();

    if ((error = persistence_->start()) != nil) {
        BSGLogError(@"error while starting persistence: %@", error);
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
                                    recurringTasks:buildRecurringTasks()];
    [worker_ start];

    workerTimer_ = [NSTimer scheduledTimerWithTimeInterval:bsgp_performWorkInterval
                                                   repeats:YES
                                                     block:^(__unused NSTimer * _Nonnull timer) {
        blockThis->onWorkInterval();
    }];

    batch_->setBatchFullCallback(^{
        blockThis->onBatchFull();
    });

    appStateTracker_.onTransitionToForeground = ^{
        blockThis->onAppEnteredForeground();
    };

    tracer_.start(configuration);

    Reachability::get().addCallback(^(Reachability::Connectivity connectivity) {
        blockThis->onConnectivityChanged(connectivity);
    });
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
    uploadPValueRequest();
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
    if (shouldPersistState_.exchange(false)) {
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
    probabilityExpiry_ = CFAbsoluteTimeGetCurrent() + bsgp_probabilityValueExpiresAfterSeconds;
    sampler_->setProbability(newProbability);
    persistentState_->setProbability(newProbability);
}

void BugsnagPerformanceImpl::onPersistentStateChanged() noexcept {
    shouldPersistState_ = true;
    wakeWorker();
}

void BugsnagPerformanceImpl::onSpanStarted() noexcept {
    // If a span starts before we've started Bugsnag, there won't be an uploader yet.
    if (uploader_ != nullptr) {
        if (CFAbsoluteTimeGetCurrent() > probabilityExpiry_) {
            uploadPValueRequest();
        }
    }
}

void BugsnagPerformanceImpl::onWorkInterval() noexcept {
    batch_->allowDrain();
    wakeWorker();
}

void BugsnagPerformanceImpl::onAppEnteredForeground() noexcept {
    batch_->allowDrain();
    wakeWorker();
}

#pragma mark Utility

void BugsnagPerformanceImpl::wakeWorker() noexcept {
    [worker_ wake];
}

void BugsnagPerformanceImpl::uploadPValueRequest() noexcept {
    auto currentTime = CFAbsoluteTimeGetCurrent();
    if (currentTime > pausePValueRequestsUntil_) {
        // Pause P-value requests so that we don't flood the server on every span start
        pausePValueRequestsUntil_ = currentTime + bsgp_probabilityRequestsPauseForSeconds;
        uploader_->upload(*OtlpTraceEncoding::buildPValueRequestPackage(), nil);
    }
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

#pragma mark Spans

BugsnagPerformanceSpan *BugsnagPerformanceImpl::startSpan(NSString *name) {
    return [[BugsnagPerformanceSpan alloc] initWithSpan:
            tracer_.startSpan(name, defaultSpanOptionsForCustom())];
}

BugsnagPerformanceSpan *BugsnagPerformanceImpl::startSpan(NSString *name, BugsnagPerformanceSpanOptions *options) {
    return [[BugsnagPerformanceSpan alloc] initWithSpan:
            tracer_.startSpan(name, SpanOptions(options))];
}

BugsnagPerformanceSpan *BugsnagPerformanceImpl::startViewLoadSpan(NSString *name, BugsnagPerformanceViewType viewType) {
    return [[BugsnagPerformanceSpan alloc] initWithSpan:
            tracer_.startViewLoadSpan(viewType, name, defaultSpanOptionsForViewLoad())];
}

BugsnagPerformanceSpan *BugsnagPerformanceImpl::startViewLoadSpan(NSString *name, BugsnagPerformanceViewType viewType, BugsnagPerformanceSpanOptions *options) {
    return [[BugsnagPerformanceSpan alloc] initWithSpan:
            tracer_.startViewLoadSpan(viewType, name, SpanOptions(options))];
}

void BugsnagPerformanceImpl::startViewLoadSpan(UIViewController *controller, BugsnagPerformanceSpanOptions *options) {
    auto span = [[BugsnagPerformanceSpan alloc] initWithSpan:
            tracer_.startViewLoadSpan(BugsnagPerformanceViewTypeUIKit,
                                        [NSString stringWithUTF8String:object_getClassName(controller)],
                                      SpanOptions(options))];

    std::lock_guard<std::mutex> guard(viewControllersToSpansMutex_);
    [viewControllersToSpans_ setObject:span forKey:controller];
}

void BugsnagPerformanceImpl::endViewLoadSpan(UIViewController *controller, NSDate *endTime) {
    /* Although NSMapTable supports weak keys, zeroed keys are not actually removed
     * until certain internal operations occur (such as the map resizing itself).
     * http://cocoamine.net/blog/2013/12/13/nsmaptable-and-zeroing-weak-references/
     *
     * This means that any spans the user forgets to end could linger beyond the deallocation
     * of their associated view controller. These span objects are small, however, so the
     * impact until the next automatic sweep are minimal.
     */

    BugsnagPerformanceSpan *span = nil;
    {
        std::lock_guard<std::mutex> guard(viewControllersToSpansMutex_);
        span = [viewControllersToSpans_ objectForKey:controller];
        [viewControllersToSpans_ removeObjectForKey:controller];
    }
    [span endWithEndTime:endTime];
}
