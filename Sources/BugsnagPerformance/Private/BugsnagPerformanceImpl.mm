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
#import "Utils.h"
#import "SpanAttributesProvider.h"
#import "SpanStackingHandler.h"
#import "BugsnagPerformanceCrossTalkAPI.h"
#import "Utils.h"
#import "FrameRateMetrics/FrameMetricsCollector.h"
#import "BugsnagPerformanceSpan+Private.h"

using namespace bugsnag;

static constexpr double SAMPLER_INTERVAL_SECONDS = 1.0;
static constexpr double SAMPLER_HISTORY_SECONDS = 10 * 60;

// App start spans will be thrown out if the early app start duration exceeds this.
static constexpr CFTimeInterval maxAppStartDuration = 2.0;

// App start spans will be thrown out if the app gets backgrounded within this timeframe after starting.
static constexpr CFTimeInterval minTimeToBackgrounding = 2.0;


static NSString *getPersistenceDir() {
    // Persistent data in bugsnag-performance can handle files disappearing, so put it in the caches dir.
    return NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
}

BugsnagPerformanceImpl::BugsnagPerformanceImpl(std::shared_ptr<Reachability> reachability,
                                               AppStateTracker *appStateTracker) noexcept
: persistence_(std::make_shared<Persistence>(getPersistenceDir()))
, persistentState_(std::make_shared<PersistentState>(persistence_))
, spanStackingHandler_(std::make_shared<SpanStackingHandler>())
, reachability_(reachability)
, batch_(std::make_shared<Batch>())
, spanAttributesProvider_(std::make_shared<SpanAttributesProvider>())
, sampler_(std::make_shared<Sampler>())
, networkHeaderInjector_(std::make_shared<NetworkHeaderInjector>(spanAttributesProvider_, spanStackingHandler_, sampler_))
, frameMetricsCollector_([FrameMetricsCollector new])
, tracer_(std::make_shared<Tracer>(spanStackingHandler_, sampler_, batch_, frameMetricsCollector_, ^{this->onSpanStarted();}))
, retryQueue_(std::make_unique<RetryQueue>([persistence_->bugsnagPerformanceDir() stringByAppendingPathComponent:@"retry-queue"]))
, appStateTracker_(appStateTracker)
, viewControllersToSpans_([NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory | NSMapTableObjectPointerPersonality
                                                valueOptions:NSMapTableStrongMemory])
, instrumentation_(std::make_shared<Instrumentation>(tracer_,
                                                     spanAttributesProvider_,
                                                     networkHeaderInjector_))
, worker_([[Worker alloc] initWithInitialTasks:buildInitialTasks() recurringTasks:buildRecurringTasks()])
, deviceID_(std::make_shared<PersistentDeviceID>(persistence_))
, resourceAttributes_(std::make_shared<ResourceAttributes>(deviceID_))
, systemInfoSampler_(SAMPLER_INTERVAL_SECONDS, SAMPLER_HISTORY_SECONDS)
, networkRequestCallback_(
    ^BugsnagPerformanceNetworkRequestInfo * _Nonnull(BugsnagPerformanceNetworkRequestInfo * _Nonnull info) {
        return info;
    }
)
{}

BugsnagPerformanceImpl::~BugsnagPerformanceImpl() {
    [workerTimer_ invalidate];
}

void BugsnagPerformanceImpl::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    BSGLogDebug(@"BugsnagPerformanceImpl::earlyConfigure()");
    // Do systemInfoSampler first so that any early spans will always have a bounding sample
    systemInfoSampler_.earlyConfigure(config);
    persistentState_->earlyConfigure(config);
    traceEncoding_.earlyConfigure(config);
    tracer_->earlyConfigure(config);
    deviceID_->earlyConfigure(config);
    resourceAttributes_->earlyConfigure(config);
    networkHeaderInjector_->earlyConfigure(config);
    retryQueue_->earlyConfigure(config);
    batch_->earlyConfigure(config);
    instrumentation_->earlyConfigure(config);
    [worker_ earlyConfigure:config];
    [frameMetricsCollector_ earlyConfigure:config];

    // Configure these here because notifications may arrive
    // before Bugsnag is started.
    __block auto blockThis = this;
    appStateTracker_.onAppFinishedLaunching = ^{
        blockThis->onAppFinishedLaunching();
    };

    appStateTracker_.onTransitionToBackground = ^{
        blockThis->onAppEnteredBackground();
    };

    appStateTracker_.onTransitionToForeground = ^{
        blockThis->onAppEnteredForeground();
    };
}

void BugsnagPerformanceImpl::earlySetup() noexcept {
    BSGLogDebug(@"BugsnagPerformanceImpl::earlySetup()");
    systemInfoSampler_.earlySetup();
    persistentState_->earlySetup();
    traceEncoding_.earlySetup();
    tracer_->earlySetup();
    deviceID_->earlySetup();
    resourceAttributes_->earlySetup();
    networkHeaderInjector_->earlySetup();
    retryQueue_->earlySetup();
    batch_->earlySetup();
    instrumentation_->earlySetup();
    [worker_ earlySetup];
    [frameMetricsCollector_ earlySetup];

    [BugsnagPerformanceCrossTalkAPI initializeWithSpanStackingHandler:spanStackingHandler_ tracer:tracer_];
}

void BugsnagPerformanceImpl::configure(BugsnagPerformanceConfiguration *config) noexcept {
    BSGLogDebug(@"BugsnagPerformanceImpl::configure()");
    performWorkInterval_ = config.internal.performWorkInterval;
    probabilityValueExpiresAfterSeconds_ = config.internal.probabilityValueExpiresAfterSeconds;
    probabilityRequestsPauseForSeconds_ = config.internal.probabilityRequestsPauseForSeconds;
    maxPackageContentLength_ = config.internal.maxPackageContentLength;
    
    auto networkRequestCallback = config.networkRequestCallback;
    if (networkRequestCallback != nullptr) {
        networkRequestCallback_ = (BugsnagPerformanceNetworkRequestCallback _Nonnull)networkRequestCallback;
    }

    configuration_ = config;
    systemInfoSampler_.configure(config);
    persistentState_->configure(config);
    traceEncoding_.configure(config);
    deviceID_->configure(config);
    resourceAttributes_->configure(config);
    tracer_->configure(config);
    networkHeaderInjector_->configure(config);
    retryQueue_->configure(config);
    batch_->configure(config);
    instrumentation_->configure(config);
    [worker_ configure:config];
    [frameMetricsCollector_ configure:config];
    [BugsnagPerformanceCrossTalkAPI.sharedInstance configure:config];
}

void BugsnagPerformanceImpl::preStartSetup() noexcept {
    BSGLogDebug(@"BugsnagPerformanceImpl::preStartSetup()");
    systemInfoSampler_.preStartSetup();
    persistentState_->preStartSetup();
    traceEncoding_.preStartSetup();
    tracer_->preStartSetup();
    deviceID_->preStartSetup();
    resourceAttributes_->preStartSetup();
    networkHeaderInjector_->preStartSetup();
    retryQueue_->preStartSetup();
    batch_->preStartSetup();
    instrumentation_->preStartSetup();
    [worker_ preStartSetup];
}

void BugsnagPerformanceImpl::start() noexcept {
    BSGLogDebug(@"BugsnagPerformanceImpl::start()");
    bool expected = false;
    if (!isStarted_.compare_exchange_strong(expected, true)) {
        // compare_exchange_strong() returns true only if isStarted_ was exchanged (from false to true).
        // Therefore, a return of false means that no exchange occurred because
        // isStarted_ was already true (i.e. we've already started).
        return;
    }

    // This is checked in two places: Bugsnag start, and NSApplicationDidFinishLaunchingNotification.
    checkAppStartDuration();

    /* Note: Be careful about initialization order!
     *
     * - Everything depends on persistence at some level
     * - uploader depends on resourceAttributes and sampler
     * - persistentState depends on persistence and will call on worker later
     * - worker depends on uploader and sampler
     * - batch depends on worker
     * - tracer depends on sampler and batch
     * - Reachability depends on worker
     * - Instrumentation depends on tracer
     */

    __block auto blockThis = this;

    persistence_->start();

    if (configuration_.internal.clearPersistenceOnStart) {
        persistence_->clearPerformanceData();
    }

    persistentState_->start();
    deviceID_->start();
    traceEncoding_.start();

    retryQueue_->setOnFilesystemError(^{
        blockThis->onFilesystemError();
    });
    retryQueue_->start();

    uploader_ = std::make_shared<OtlpUploader>(configuration_.endpoint,
                                               configuration_.apiKey,
                                                   ^(double newProbability) {
        if (configuration_.samplingProbability != nil) {
            BSGLogTrace(@"BugsnagPerformanceImpl::newProbabilityCallback: configuration_.samplingProbability != nil");
            return;
        }
        blockThis->onProbabilityChanged(newProbability);
    });
    
    double samplingProbability = persistentState_->probability();
    if (configuration_.samplingProbability != nil) {
        samplingProbability = [configuration_.samplingProbability doubleValue];
    }
    sampler_->setProbability(samplingProbability);

    resourceAttributes_->start();
    networkHeaderInjector_->start();

    systemInfoSampler_.start();

    [worker_ start];
    [frameMetricsCollector_ start];

    workerTimer_ = [NSTimer scheduledTimerWithTimeInterval:performWorkInterval_
                                                   repeats:YES
                                                     block:^(__unused NSTimer * _Nonnull timer) {
        blockThis->onWorkInterval();
    }];

    auto initialWorkDelay = configuration_.internal.initialRecurringWorkDelay;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(initialWorkDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        wakeWorker();
    });

    batch_->setBatchFullCallback(^{
        blockThis->onBatchFull();
    });

    tracer_->start();

    reachability_->addCallback(^(Reachability::Connectivity connectivity) {
        blockThis->onConnectivityChanged(connectivity);
    });

    instrumentation_->start();

    // Send the initial P value request early on.
    uploadPValueRequest();

    if (!configuration_.shouldSendReports) {
        BSGLogInfo("Note: No reports will be sent because releaseStage '%@' is not in enabledReleaseStages", configuration_.releaseStage);
    }
}

#pragma mark Tasks

NSArray<Task> *BugsnagPerformanceImpl::buildInitialTasks() noexcept {
    return @[];
}

NSArray<Task> *BugsnagPerformanceImpl::buildRecurringTasks() noexcept {
    __block auto blockThis = this;
    return @[
        ^bool() { return blockThis->sendCurrentBatchTask(); },
        ^bool() { return blockThis->sendRetriesTask(); },
        ^bool() { return blockThis->sweepTracerTask(); },
    ];
}

NSMutableArray<BugsnagPerformanceSpan *> *
BugsnagPerformanceImpl::sendableSpans(NSMutableArray<BugsnagPerformanceSpan *> *spans) noexcept {
    NSMutableArray<BugsnagPerformanceSpan *> *sendableSpans = [NSMutableArray arrayWithCapacity:spans.count];
    for (BugsnagPerformanceSpan *span in spans) {
        if (span.state != SpanStateAborted && sampler_->sampled(span)) {
            [sendableSpans addObject:span];
        }
    }
    return sendableSpans;
}

bool BugsnagPerformanceImpl::shouldSampleCPU(BugsnagPerformanceSpan *span) noexcept {
    if (span.metricsOptions.cpu == BSGTriStateUnset) {
        return span.firstClass == BSGTriStateYes;
    }
    return span.metricsOptions.cpu == BSGTriStateYes;
}

bool BugsnagPerformanceImpl::sendCurrentBatchTask() noexcept {
    BSGLogDebug(@"BugsnagPerformanceImpl::sendCurrentBatchTask()");
    auto origSpans = batch_->drain(false);
#ifndef __clang_analyzer__
    #pragma clang diagnostic ignored "-Wunused-variable"
    size_t origSpansSize = origSpans.count;
#endif
    auto spans = sendableSpans(origSpans);
    if (spans.count == 0) {
#ifndef __clang_analyzer__
        BSGLogTrace(@"BugsnagPerformanceImpl::sendCurrentBatchTask(): Nothing to send. origSpans size = %zu", origSpansSize);
#endif
        return false;
    }
    bool includeSamplingHeader = configuration_ == nil || configuration_.samplingProbability == nil;

    // Delay so that the sampler has time to fetch one more sample.
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((SAMPLER_INTERVAL_SECONDS + 0.5) * NSEC_PER_SEC)),
//                   dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
//        BSGLogTrace(@"BugsnagPerformanceImpl::sendCurrentBatchTask(): Delayed %f seconds, now getting system info", SAMPLER_INTERVAL_SECONDS + 0.5);
//        for(BugsnagPerformanceSpan *span: spans) {
//            auto samples = systemInfoSampler_.samplesAroundTimePeriod(span.actuallyStartedAt, span.actuallyEndedAt);
//            BSGLogTrace(@"BugsnagPerformanceImpl::sendCurrentBatchTask(): System info sample size = %zu", samples.size());
//            if (samples.size() >= 2) {
//                if (shouldSampleCPU(span)) {
//                    BSGLogTrace(@"BugsnagPerformanceImpl::sendCurrentBatchTask(): Getting CPU sample attributes for span %@", span.name);
//                    [span forceMutate:^() {
//                        [span internalSetMultipleAttributes:spanAttributesProvider_->cpuSampleAttributes(samples)];
//                    }];
//                }
//            }
//        }

#ifndef __clang_analyzer__
        BSGLogTrace(@"BugsnagPerformanceImpl::sendCurrentBatchTask(): Sending %zu sampled spans (out of %zu)", origSpansSize, spans.count);
#endif
        uploadPackage(traceEncoding_.buildUploadPackage(spans, resourceAttributes_->get(), includeSamplingHeader), false);
//    });

    return true;
}

bool BugsnagPerformanceImpl::sendRetriesTask() noexcept {
    BSGLogDebug(@"BugsnagPerformanceImpl::sendRetriesTask()");
    retryQueue_->sweep();

    auto retries = retryQueue_->list();
    if (retries.size() == 0) {
        BSGLogTrace(@"BugsnagPerformanceImpl::sendRetriesTask(): No retries to send");
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

bool BugsnagPerformanceImpl::sweepTracerTask() noexcept {
    BSGLogDebug(@"BugsnagPerformanceImpl::sweepTracerTask()");
    tracer_->sweep();
    // Never auto-repeat this task, even if work was done; it can wait.
    return false;
}

#pragma mark Event Reactions

void BugsnagPerformanceImpl::onFilesystemError() noexcept {
    persistence_->clearPerformanceData();
}

void BugsnagPerformanceImpl::onBatchFull() noexcept {
    BSGLogDebug(@"BugsnagPerformanceImpl::onBatchFull()");
    wakeWorker();
}

void BugsnagPerformanceImpl::onConnectivityChanged(Reachability::Connectivity connectivity) noexcept {
    BSGLogDebug(@"BugsnagPerformanceImpl::onConnectivityChanged(): new reachability = %d", connectivity);
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
    BSGLogDebug(@"BugsnagPerformanceImpl::onProbabilityChanged(): new probability = %f, expiring after %f seconds", newProbability, probabilityValueExpiresAfterSeconds_);
    probabilityExpiry_ = CFAbsoluteTimeGetCurrent() + probabilityValueExpiresAfterSeconds_;
    sampler_->setProbability(newProbability);
    persistentState_->setProbability(newProbability);
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
    BSGLogTrace(@"BugsnagPerformanceImpl::onWorkInterval()");
    batch_->allowDrain();
    wakeWorker();
}

void BugsnagPerformanceImpl::onAppFinishedLaunching() noexcept {
    BSGLogDebug(@"BugsnagPerformanceImpl::onAppFinishedLaunching()");
    // We run this without checking isStarted (in case there's notification
    // timing jank and we get the notification before we've started).
    checkAppStartDuration();
}

void BugsnagPerformanceImpl::onAppEnteredBackground() noexcept {
    BSGLogDebug(@"BugsnagPerformanceImpl::onAppEnteredBackground()");
    [frameMetricsCollector_ onAppEnteredBackground];
    
    // We run this BEFORE checking isStarted (in case there's notification
    // timing jank and we get the notification before we've started).
    if (instrumentation_->timeSinceAppFirstBecameActive() < minTimeToBackgrounding) {
        // If we get backgrounded too quickly after app start, throw out
        // all app start spans even if they've completed.
        // Sometimes the jank between backgrounding/foregrounding events
        // can cause the spans to close very late, so we play it safe.
        instrumentation_->abortAppStartupSpans();
    }

    if (!isStarted_) {
        return;
    }

    tracer_->abortAllOpenSpans();
}

void BugsnagPerformanceImpl::onAppEnteredForeground() noexcept {
    [frameMetricsCollector_ onAppEnteredForeground];
    if (!isStarted_) {
        BSGLogDebug(@"BugsnagPerformanceImpl::onAppEnteredForeground(), but not started yet");
        return;
    }
    BSGLogDebug(@"BugsnagPerformanceImpl::onAppEnteredForeground()");

    batch_->allowDrain();
    wakeWorker();
}

#pragma mark Utility

void BugsnagPerformanceImpl::wakeWorker() noexcept {
    BSGLogTrace(@"BugsnagPerformanceImpl::wakeWorker()");
    [worker_ wake];
}

void BugsnagPerformanceImpl::checkAppStartDuration() noexcept {
    if (!hasCheckedAppStartDuration_) {
        hasCheckedAppStartDuration_ = true;
        if (instrumentation_->appStartDuration() > maxAppStartDuration) {
            instrumentation_->abortAppStartupSpans();
        }
    }
}

void BugsnagPerformanceImpl::uploadPValueRequest() noexcept {
    if (!configuration_.shouldSendReports || configuration_.samplingProbability != nil) {
        return;
    }
    auto currentTime = CFAbsoluteTimeGetCurrent();
    if (currentTime > pausePValueRequestsUntil_) {
        // Pause P-value requests so that we don't flood the server on every span start
        pausePValueRequestsUntil_ = currentTime + probabilityRequestsPauseForSeconds_;
        uploader_->upload(*traceEncoding_.buildPValueRequestPackage(), nil);
    }
}

void BugsnagPerformanceImpl::uploadPackage(std::unique_ptr<OtlpPackage> package, bool isRetry) noexcept {
    BSGLogDebug(@"BugsnagPerformanceImpl::uploadPackage(package, isRetry:%s)", isRetry ? "yes" : "no");
    if (!configuration_.shouldSendReports) {
        BSGLogTrace(@"BugsnagPerformanceImpl::uploadPackage: !configuration_.shouldSendReports");
        return;
    }
    if (package == nullptr) {
        BSGLogTrace(@"BugsnagPerformanceImpl::uploadPackage: package == nullptr");
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
                if (!isRetry && blockPackage->uncompressedContentLength() <= maxPackageContentLength_) {
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

BugsnagPerformanceSpan *BugsnagPerformanceImpl::startCustomSpan(NSString *name) noexcept {
    SpanOptions options;
    auto span = tracer_->startCustomSpan(name, options);
    [span internalSetMultipleAttributes:spanAttributesProvider_->customSpanAttributes()];
    return span;
}

BugsnagPerformanceSpan *BugsnagPerformanceImpl::startCustomSpan(NSString *name, BugsnagPerformanceSpanOptions *optionsIn) noexcept {
    auto options = SpanOptions(optionsIn);
    auto span = tracer_->startCustomSpan(name, options);
    [span internalSetMultipleAttributes:spanAttributesProvider_->customSpanAttributes()];
    return span;
}

BugsnagPerformanceSpan *BugsnagPerformanceImpl::startViewLoadSpan(NSString *className, BugsnagPerformanceViewType viewType) noexcept {
    SpanOptions options;
    auto span = tracer_->startViewLoadSpan(viewType, className, options);
    [span internalSetMultipleAttributes:spanAttributesProvider_->viewLoadSpanAttributes(className, viewType)];
    return span;
}

BugsnagPerformanceSpan *BugsnagPerformanceImpl::startViewLoadSpan(NSString *className, BugsnagPerformanceViewType viewType, BugsnagPerformanceSpanOptions *optionsIn) noexcept {
    auto options = SpanOptions(optionsIn);
    auto span = tracer_->startViewLoadSpan(viewType, className, options);
    [span internalSetMultipleAttributes:spanAttributesProvider_->viewLoadSpanAttributes(className, viewType)];
    return span;
}

void BugsnagPerformanceImpl::startViewLoadSpan(UIViewController *controller, BugsnagPerformanceSpanOptions *optionsIn) noexcept {
    auto options = SpanOptions(optionsIn);
    auto viewType = BugsnagPerformanceViewTypeUIKit;
    auto className = [NSString stringWithUTF8String:object_getClassName(controller)];
    auto span = tracer_->startViewLoadSpan(viewType, className, options);
    [span internalSetMultipleAttributes:spanAttributesProvider_->viewLoadSpanAttributes(className, viewType)];

    std::lock_guard<std::mutex> guard(viewControllersToSpansMutex_);
    [viewControllersToSpans_ setObject:span forKey:controller];
}

BugsnagPerformanceSpan *BugsnagPerformanceImpl::startViewLoadPhaseSpan(NSString *className, NSString *phase,
                                                                       BugsnagPerformanceSpanContext *parentContext) noexcept {
    auto span = tracer_->startViewLoadPhaseSpan(className, phase, parentContext);
    [span internalSetMultipleAttributes:spanAttributesProvider_->viewLoadPhaseSpanAttributes(className, phase)];
    return span;
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

void BugsnagPerformanceImpl::reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept {
    BugsnagPerformanceSpan *span = nil;

    NSError *errorFromGetRequest = nil;
    NSURLRequest *req = getTaskRequest(task, &errorFromGetRequest);
    BSGLogDebug(@"BugsnagPerformanceImpl::reportNetworkSpan() for %@", req.URL);

    auto info = [BugsnagPerformanceNetworkRequestInfo new];
    info.url = req.URL;
    bool userVetoedTracing = false;
    if (info.url != nil) {
        info = networkRequestCallback_(info);
        userVetoedTracing = info.url == nil;
    }
    if (!userVetoedTracing) {
        auto interval = metrics.taskInterval;
        auto name = req.HTTPMethod;
        SpanOptions options;
        options.makeCurrentContext = false;
        options.startTime = dateToAbsoluteTime(interval.startDate);
        span = tracer_->startNetworkSpan(name, options);
        [span internalSetMultipleAttributes:spanAttributesProvider_->networkSpanAttributes(info.url, task, metrics, errorFromGetRequest)];
        [span endWithEndTime:interval.endDate];
    }
}
