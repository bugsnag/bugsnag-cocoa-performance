//
//  BugsnagPerformanceImpl.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 15.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "BugsnagPerformanceImpl.h"
#import "BugsnagPerformanceConfiguration+Private.h"

#import "OtlpTraceEncoding.h"
#import "ResourceAttributes.h"
#import "SpanContextStack.h"
#import "Utils.h"

using namespace bugsnag;

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

BugsnagPerformanceImpl::BugsnagPerformanceImpl(std::shared_ptr<Reachability> reachability,
                                               AppStateTracker *appStateTracker) noexcept
: persistence_(std::make_shared<Persistence>(getPersistenceDir()))
, spanContextStack_([SpanContextStack new])
, reachability_(reachability)
, batch_(std::make_shared<Batch>())
, sampler_(std::make_shared<Sampler>())
, tracer_(spanContextStack_, sampler_, batch_, generateOnSpanStarted(this))
, retryQueue_(std::make_unique<RetryQueue>([persistence_->topLevelDirectory() stringByAppendingPathComponent:@"retry-queue"]))
, appStateTracker_(appStateTracker)
, viewControllersToSpans_([NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory | NSMapTableObjectPointerPersonality
                                                valueOptions:NSMapTableStrongMemory])
{}

BugsnagPerformanceImpl::~BugsnagPerformanceImpl() {
    [workerTimer_ invalidate];
}

void BugsnagPerformanceImpl::configure(BugsnagPerformanceConfiguration *configuration) noexcept {
    performWorkInterval_ = configuration.internal.performWorkInterval;
    probabilityValueExpiresAfterSeconds_ = configuration.internal.probabilityValueExpiresAfterSeconds;
    probabilityRequestsPauseForSeconds_ = configuration.internal.probabilityRequestsPauseForSeconds;

    configuration_ = configuration;
    tracer_.configure(configuration);
    retryQueue_->configure(configuration);
    batch_->configure(configuration);
}

void BugsnagPerformanceImpl::start() noexcept {
    bool expected = false;
    if (!isStarted_.compare_exchange_strong(expected, true)) {
        // compare_exchange_strong() returns true only if isStarted_ was exchanged (from false to true).
        // Therefore, a return of false means that no exchange occurred because
        // isStarted_ was already true (i.e. we've already started).
        return;
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

    persistence_->start();

    if (configuration_.internal.clearPersistenceOnStart) {
        persistence_->clear();
    }

    resourceAttributes_ = ResourceAttributes(configuration_).get();

    retryQueue_->setOnFilesystemError(^{
        blockThis->onFilesystemError();
    });
    retryQueue_->start();

    uploader_ = std::make_shared<OtlpUploader>(configuration_.endpoint,
                                               configuration_.apiKey,
                                                   ^(double newProbability) {
        blockThis->onProbabilityChanged(newProbability);
    });

    auto persistentStateFile = [persistence_->topLevelDirectory() stringByAppendingPathComponent:@"persistent-state.json"];
    persistentState_ = std::make_shared<PersistentState>(persistentStateFile, ^void() {
        blockThis->onPersistentStateChanged();
    });

    if (persistentState_->probabilityIsValid()) {
        sampler_->setProbability(persistentState_->probability());
    } else {
        sampler_->setProbability(configuration_.samplingProbability);
    }

    worker_ = [[Worker alloc] initWithInitialTasks:buildInitialTasks()
                                    recurringTasks:buildRecurringTasks()];
    [worker_ start];

    workerTimer_ = [NSTimer scheduledTimerWithTimeInterval:performWorkInterval_
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

    tracer_.start();

    reachability_->addCallback(^(Reachability::Connectivity connectivity) {
        blockThis->onConnectivityChanged(connectivity);
    });

    if (!configuration_.shouldSendReports) {
        BSGLogInfo("Note: No reports will be sent because releaseStage '%@' is not in enabledReleaseStages", configuration_.releaseStage);
    }
}

#pragma mark Tasks

NSArray<Task> *BugsnagPerformanceImpl::buildInitialTasks() noexcept {
    __block auto blockThis = this;
    return @[
        ^bool() { return blockThis->sendPValueRequestTask(); },
    ];
}

NSArray<Task> *BugsnagPerformanceImpl::buildRecurringTasks() noexcept {
    __block auto blockThis = this;
    return @[
        ^bool() { return blockThis->maybePersistStateTask(); },
        ^bool() { return blockThis->sendCurrentBatchTask(); },
        ^bool() { return blockThis->sendRetriesTask(); },
    ];
}

bool BugsnagPerformanceImpl::sendPValueRequestTask() noexcept {
    uploadPValueRequest();
    return true;
}

bool BugsnagPerformanceImpl::sendCurrentBatchTask() noexcept {
    auto spans = sampler_->sampled(batch_->drain());
    if (spans->size() == 0) {
        return false;
    }

    uploadPackage(OtlpTraceEncoding::buildUploadPackage(*spans, resourceAttributes_), false);
    return true;
}

bool BugsnagPerformanceImpl::sendRetriesTask() noexcept {
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

bool BugsnagPerformanceImpl::maybePersistStateTask() noexcept {
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
    probabilityExpiry_ = CFAbsoluteTimeGetCurrent() + probabilityValueExpiresAfterSeconds_;
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
    if (!configuration_.shouldSendReports) {
        return;
    }
    auto currentTime = CFAbsoluteTimeGetCurrent();
    if (currentTime > pausePValueRequestsUntil_) {
        // Pause P-value requests so that we don't flood the server on every span start
        pausePValueRequestsUntil_ = currentTime + probabilityRequestsPauseForSeconds_;
        uploader_->upload(*OtlpTraceEncoding::buildPValueRequestPackage(), nil);
    }
}

void BugsnagPerformanceImpl::uploadPackage(std::unique_ptr<OtlpPackage> package, bool isRetry) noexcept {
    if (!configuration_.shouldSendReports) {
        return;
    }
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

void BugsnagPerformanceImpl::possiblyMakeSpanCurrent(BugsnagPerformanceSpan *span, SpanOptions &options) {
    if (options.makeContextCurrent) {
        [spanContextStack_ push:span];
    }
}

BugsnagPerformanceSpan *BugsnagPerformanceImpl::startSpan(NSString *name) noexcept {
    SpanOptions options;
    auto span = tracer_.startCustomSpan(name, options);
    possiblyMakeSpanCurrent(span, options);
    return span;
}

BugsnagPerformanceSpan *BugsnagPerformanceImpl::startSpan(NSString *name, BugsnagPerformanceSpanOptions *optionsIn) noexcept {
    auto options = SpanOptions(optionsIn);
    auto span = tracer_.startCustomSpan(name, options);
    possiblyMakeSpanCurrent(span, options);
    return span;
}

BugsnagPerformanceSpan *BugsnagPerformanceImpl::startViewLoadSpan(NSString *name, BugsnagPerformanceViewType viewType) noexcept {
    SpanOptions options;
    auto span = tracer_.startViewLoadSpan(viewType, name, options);
    possiblyMakeSpanCurrent(span, options);
    return span;
}

BugsnagPerformanceSpan *BugsnagPerformanceImpl::startViewLoadSpan(NSString *name, BugsnagPerformanceViewType viewType, BugsnagPerformanceSpanOptions *optionsIn) noexcept {
    auto options = SpanOptions(optionsIn);
    auto span = tracer_.startViewLoadSpan(viewType, name, options);
    possiblyMakeSpanCurrent(span, options);
    return span;
}

void BugsnagPerformanceImpl::startViewLoadSpan(UIViewController *controller, BugsnagPerformanceSpanOptions *optionsIn) noexcept {
    auto options = SpanOptions(optionsIn);
    auto span = tracer_.startViewLoadSpan(BugsnagPerformanceViewTypeUIKit,
                                          [NSString stringWithUTF8String:object_getClassName(controller)],
                                          options);
    possiblyMakeSpanCurrent(span, options);

    std::lock_guard<std::mutex> guard(viewControllersToSpansMutex_);
    [viewControllersToSpans_ setObject:span forKey:controller];
}

void BugsnagPerformanceImpl::endViewLoadSpan(UIViewController *controller, NSDate *endTime) noexcept {
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

BugsnagPerformanceSpan *BugsnagPerformanceImpl::startAppStartSpan(NSString *name, SpanOptions options) noexcept {
    return tracer_.startAppStartSpan(name, options);
}

void BugsnagPerformanceImpl::cancelQueuedSpan(BugsnagPerformanceSpan *span) noexcept {
    tracer_.cancelQueuedSpan(span);
}
