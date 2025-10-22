//
//  BugsnagPerformanceImpl.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 15.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "BugsnagPerformanceImpl.h"
#import "../Core/Configuration/BugsnagPerformanceConfiguration+Private.h"

#import "../Upload/Otlp/OtlpTraceEncoding.h"
#import "../Utils/Utils.h"
#import "../Core/Attributes/SpanAttributesProvider.h"
#import "../Core/SpanStack/SpanStackingHandler.h"
#import "../CrossTalkAPI/BugsnagPerformanceCrossTalkAPI.h"
#import "../Utils/Utils.h"
#import "../Metrics/FrameMetrics/FrameMetricsCollector.h"
#import "../Core/SpanConditions/ConditionTimeoutExecutor.h"
#import "../Core/Span/BugsnagPerformanceSpan+Private.h"
#import "../Plugins/AppStart/BugsnagPerformanceAppStartTypePlugin.h"

using namespace bugsnag;

void BugsnagPerformanceImpl::initialize() noexcept {
    viewControllersToSpans_ = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory | NSMapTableObjectPointerPersonality
                                                    valueOptions:NSMapTableStrongMemory];
    mainModule_->setUp();
}

void BugsnagPerformanceImpl::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    mainModule_->earlyConfigure(config);
}

void BugsnagPerformanceImpl::earlySetup() noexcept {
    mainModule_->earlySetup();
}

void BugsnagPerformanceImpl::configure(BugsnagPerformanceConfiguration *config) noexcept {
    BSGLogDebug(@"BugsnagPerformanceImpl::configure()");
    maxPackageContentLength_ = config.internal.maxPackageContentLength;

    configuration_ = config;
    mainModule_->configure(config);
}

void BugsnagPerformanceImpl::preStartSetup() noexcept {
    mainModule_->preStartSetup();
}

void BugsnagPerformanceImpl::start() noexcept {
    bool expected = false;
    if (!isStarted_.compare_exchange_strong(expected, true)) {
        // compare_exchange_strong() returns true only if isStarted_ was exchanged (from false to true).
        // Therefore, a return of false means that no exchange occurred because
        // isStarted_ was already true (i.e. we've already started).
        return;
    }

    mainModule_->start();

    if (!configuration_.shouldSendReports) {
        BSGLogInfo("Note: No reports will be sent because releaseStage '%@' is not in enabledReleaseStages", configuration_.releaseStage);
    }
}

#pragma mark Event Reactions


// TODO: Replace with worker task
//void BugsnagPerformanceImpl::onSpanStarted() noexcept {
//    // If a span starts before we've started Bugsnag, there won't be an uploader yet.
//    if (uploader_ != nullptr) {
//        if (CFAbsoluteTimeGetCurrent() > probabilityExpiry_) {
//            uploadPValueRequest();
//        }
//    }
//}

void
BugsnagPerformanceImpl::loadingIndicatorWasAdded(BugsnagPerformanceLoadingIndicatorView *loadingViewIndicator) noexcept {
    mainModule_->getInstrumentationModule()->loadingIndicatorWasAdded(loadingViewIndicator);
}

#pragma mark Utility

// TODO: Initial task
//void BugsnagPerformanceImpl::uploadPValueRequest() noexcept {
//    if (!configuration_.shouldSendReports || configuration_.samplingProbability != nil) {
//        return;
//    }
//    auto currentTime = CFAbsoluteTimeGetCurrent();
//    if (currentTime > pausePValueRequestsUntil_) {
//        // Pause P-value requests so that we don't flood the server on every span start
//        pausePValueRequestsUntil_ = currentTime + probabilityRequestsPauseForSeconds_;
//        uploader_->upload(*traceEncoding_.buildPValueRequestPackage(), nil);
//    }
//}

// TODO: Move to worker task
//void BugsnagPerformanceImpl::uploadPackage(std::unique_ptr<OtlpPackage> package, bool isRetry) noexcept {
//    BSGLogDebug(@"BugsnagPerformanceImpl::uploadPackage(package, isRetry:%s)", isRetry ? "yes" : "no");
//    if (!configuration_.shouldSendReports) {
//        BSGLogTrace(@"BugsnagPerformanceImpl::uploadPackage: !configuration_.shouldSendReports");
//        return;
//    }
//    if (package == nullptr) {
//        BSGLogTrace(@"BugsnagPerformanceImpl::uploadPackage: package == nullptr");
//        return;
//    }
//
//    // Give up waiting for the upload after 20 seconds
//    NSTimeInterval maxWaitInterval = 20.0;
//
//    __block auto blockThis = this;
//    __block std::unique_ptr<OtlpPackage> blockPackage = std::move(package);
//    __block auto condition = [NSCondition new];
//
//    [condition lock];
//    uploader_->upload(*blockPackage, ^(UploadResult result) {
//        switch (result) {
//            case UploadResult::SUCCESSFUL:
//                if (isRetry) {
//                    blockThis->retryQueue_->remove(blockPackage->timestamp);
//                }
//                break;
//            case UploadResult::FAILED_CAN_RETRY:
//                if (!isRetry && blockPackage->uncompressedContentLength() <= maxPackageContentLength_) {
//                    blockThis->retryQueue_->add(*blockPackage);
//                }
//                break;
//            case UploadResult::FAILED_CANNOT_RETRY:
//                // We can't do anything with it, so throw it out.
//                if (isRetry) {
//                    blockThis->retryQueue_->remove(blockPackage->timestamp);
//                }
//                break;
//        }
//        [condition lock];
//        [condition signal];
//        [condition unlock];
//    });
//    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:maxWaitInterval];
//    [condition waitUntilDate:timeoutDate];
//    [condition unlock];
//}

#pragma mark Spans

BugsnagPerformanceSpan *
BugsnagPerformanceImpl::startCustomSpan(NSString *name) noexcept {
    SpanOptions options;
    auto attributes = mainModule_->getCoreModule()->getSpanAttributesProvider()->customSpanAttributes();
    return mainModule_->getCoreModule()->getPlainSpanFactory()->startSpan(name, options, BSGTriStateYes, attributes, @[]);
}

BugsnagPerformanceSpan *
BugsnagPerformanceImpl::startCustomSpan(NSString *name, BugsnagPerformanceSpanOptions *optionsIn) noexcept {
    auto options = SpanOptions(optionsIn);
    auto attributes = mainModule_->getCoreModule()->getSpanAttributesProvider()->customSpanAttributes();
    return mainModule_->getCoreModule()->getPlainSpanFactory()->startSpan(name, options, BSGTriStateYes, attributes, @[]);
}

BugsnagPerformanceSpan *
BugsnagPerformanceImpl::startViewLoadSpan(NSString *className, BugsnagPerformanceViewType viewType) noexcept {
    SpanOptions options;
    return mainModule_->getCoreModule()->getViewLoadSpanFactory()->startViewLoadSpan(viewType,
                                                                                     className,
                                                                                     nil,
                                                                                     options,
                                                                                     @{});
}

BugsnagPerformanceSpan *
BugsnagPerformanceImpl::startViewLoadSpan(NSString *className, BugsnagPerformanceViewType viewType, BugsnagPerformanceSpanOptions *optionsIn) noexcept {
    auto options = SpanOptions(optionsIn);
    return mainModule_->getCoreModule()->getViewLoadSpanFactory()->startViewLoadSpan(viewType,
                                                                                     className,
                                                                                     nil,
                                                                                     options,
                                                                                     @{});
}

void
BugsnagPerformanceImpl::startViewLoadSpan(UIViewController *controller, BugsnagPerformanceSpanOptions *optionsIn) noexcept {
    auto options = SpanOptions(optionsIn);
    auto viewType = BugsnagPerformanceViewTypeUIKit;
    auto className = [NSString stringWithUTF8String:object_getClassName(controller)];
    auto span = mainModule_->getCoreModule()->getViewLoadSpanFactory()->startViewLoadSpan(viewType,
                                                                                          className,
                                                                                          nil,
                                                                                          options,
                                                                                          @{});
    std::lock_guard<std::mutex> guard(viewControllersToSpansMutex_);
    [viewControllersToSpans_ setObject:span forKey:controller];
}

BugsnagPerformanceSpan *
BugsnagPerformanceImpl::startViewLoadPhaseSpan(NSString *className,
                                               NSString *phase,
                                               BugsnagPerformanceSpanContext *parentContext) noexcept {
    return mainModule_->getCoreModule()->getViewLoadSpanFactory()->startViewLoadPhaseSpan(className,
                                                                                          parentContext,
                                                                                          phase,
                                                                                          @[]);
}

void
BugsnagPerformanceImpl::endViewLoadSpan(UIViewController *controller, NSDate *endTime) noexcept {
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
    mainModule_->getCoreModule()->getNetworkSpanReporter()->reportNetworkSpan(task, metrics);
}
