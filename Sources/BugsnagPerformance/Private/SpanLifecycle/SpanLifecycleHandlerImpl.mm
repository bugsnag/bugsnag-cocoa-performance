//
//  SpanLifecycleHandlerImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 09/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "SpanLifecycleHandlerImpl.h"
#import "../BugsnagPerformanceSpan+Private.h"

using namespace bugsnag;


void
SpanLifecycleHandlerImpl::preStartSetup() noexcept {
    reprocessEarlySpans();
}

void
SpanLifecycleHandlerImpl::onSpanStarted(BugsnagPerformanceSpan *span, const SpanOptions &options) noexcept {
    if (shouldInstrumentRendering(span)) {
        span.startFramerateSnapshot = [frameMetricsCollector_ currentSnapshot];
    }
    store_->addNewSpan(span, options.makeCurrentContext);
    callOnSpanStartCallbacks(span);
    onSpanStarted_();
}

void
SpanLifecycleHandlerImpl::onSpanEndSet(BugsnagPerformanceSpan *span) noexcept {
    if (shouldInstrumentRendering(span)) {
        span.endFramerateSnapshot = [frameMetricsCollector_ currentSnapshot];
    }
}

void
SpanLifecycleHandlerImpl::onSpanClosed(BugsnagPerformanceSpan *span) noexcept {
    if (!span.isBlocked) {
        processClosedSpan(span);
    }
}

BugsnagPerformanceSpanCondition *
SpanLifecycleHandlerImpl::onSpanBlocked(BugsnagPerformanceSpan *span, NSTimeInterval timeout) noexcept {
    if(span == nil || timeout <= 0) {
        return nil;
    }
    if (span.state != SpanStateOpen && !span.isBlocked) {
        return nil;
    }
    BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:span onClosedCallback:^(BugsnagPerformanceSpanCondition *c, CFAbsoluteTime endTime) {
        __strong BugsnagPerformanceSpan *strongSpan = c.span;
        if (strongSpan.state == SpanStateEnded && endTime > strongSpan.endAbsTime) {
            [strongSpan markEndAbsoluteTime:endTime];
        }
    } onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *c) {
        __strong BugsnagPerformanceSpan *strongSpan = c.span;
        this->conditionTimeoutExecutor_->cancelTimeout(c);
        
        @synchronized (c) {
            if (c.isActive) {
                return strongSpan;
            }
        }
        return nil;
    }];
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *c) {
        __strong BugsnagPerformanceSpan *strongSpan = c.span;
        if (strongSpan.state == SpanStateEnded && !strongSpan.isBlocked) {
            this->store_->removeSpanFromBlocked(span);
            this->conditionTimeoutExecutor_->cancelTimeout(c);
            this->onSpanClosed(strongSpan);
        }
    }];
    conditionTimeoutExecutor_->scheduleTimeout(condition, timeout);
    store_->addSpanToBlocked(span);
    return condition;
}

void
SpanLifecycleHandlerImpl::onSpanCancelled(BugsnagPerformanceSpan *span) noexcept {
    if (!span) {
        return;
    }
    batch_->removeSpan(span.traceIdHi, span.traceIdLo, span.spanId);
    if (span.isBlocked) {
        store_->removeSpanFromBlocked(span);
    }
}

void
SpanLifecycleHandlerImpl::onAppEnteredBackground() noexcept {
    if (isStarted_) {
        abortAllOpenSpans();
    }
}

#pragma mark Private

bool
SpanLifecycleHandlerImpl::shouldInstrumentRendering(BugsnagPerformanceSpan *span) noexcept {
    switch (span.metricsOptions.rendering) {
        case BSGTriStateYes:
            return enabledMetrics_.rendering;
        case BSGTriStateNo:
            return false;
        case BSGTriStateUnset:
            return enabledMetrics_.rendering &&
            !span.wasStartOrEndTimeProvided &&
            span.firstClass == BSGTriStateYes;
    }
}

void
SpanLifecycleHandlerImpl::processFrameMetrics(BugsnagPerformanceSpan *span) noexcept {
    auto startSnapshot = span.startFramerateSnapshot;
    auto endSnapshot = span.endFramerateSnapshot;
    if (!shouldInstrumentRendering(span) ||
        startSnapshot == nil ||
        endSnapshot == nil) {
        return;
    }
    auto mergedSnapshot = [FrameMetricsSnapshot mergeWithStart:startSnapshot
                                                           end:endSnapshot];
    if (mergedSnapshot.totalFrames == 0) {
        return;
    }
    [span forceMutate:^{
        [span setAttribute:@"bugsnag.rendering.total_frames" withValue:@(mergedSnapshot.totalFrames)];
        [span setAttribute:@"bugsnag.rendering.slow_frames" withValue:@(mergedSnapshot.totalSlowFrames)];
        [span setAttribute:@"bugsnag.rendering.frozen_frames" withValue:@(mergedSnapshot.totalFrozenFrames)];
    }];
    
    auto frozenFrame = mergedSnapshot.firstFrozenFrame;
    while (frozenFrame != nil) {
        createFrozenFrameSpan(frozenFrame.startTime, frozenFrame.endTime, span);
        frozenFrame = frozenFrame != mergedSnapshot.lastFrozenFrame ? frozenFrame.next : nil;
    }
}

void
SpanLifecycleHandlerImpl::callOnSpanStartCallbacks(BugsnagPerformanceSpan *span) noexcept {
    if(span == nil) {
        return;
    }

    for (BugsnagPerformanceSpanStartCallback callback: [onSpanStartCallbacks_ objects]) {
        @try {
            callback(span);
        } @catch(NSException *e) {
            BSGLogError(@"SpanLifecycleHandlerImpl::callOnSpanStartCallbacks: span onStart callback threw exception: %@", e);
        }
    }
}

void
SpanLifecycleHandlerImpl::callOnSpanEndCallbacks(BugsnagPerformanceSpan *span) noexcept {
    if(span == nil) {
        return;
    }
    if (span.state != SpanStateEnded) {
        return;
    }

    CFAbsoluteTime callbacksStartTime = CFAbsoluteTimeGetCurrent();
    for (BugsnagPerformanceSpanEndCallback callback: [onSpanEndCallbacks_ objects]) {
        BOOL shouldDiscardSpan = false;
        @try {
            shouldDiscardSpan = !callback(span);
        } @catch(NSException *e) {
            BSGLogError(@"Tracer::callOnSpanEndCallbacks: span OnEnd callback threw exception: %@", e);
            // We don't know whether they wanted to discard the span or not, so keep it.
            shouldDiscardSpan = false;
        }
        if(shouldDiscardSpan) {
            [span abortUnconditionally];
            return;
        }
    }
    CFAbsoluteTime callbacksEndTime = CFAbsoluteTimeGetCurrent();
    [span internalSetAttribute:@"bugsnag.span.callbacks_duration" withValue:@(intervalToNanoseconds(callbacksEndTime - callbacksStartTime))];
}

void
SpanLifecycleHandlerImpl::createFrozenFrameSpan(NSTimeInterval startTime,
                                                NSTimeInterval endTime,
                                                BugsnagPerformanceSpanContext *parentContext) noexcept {
    SpanOptions options;
    options.startTime = startTime;
    options.parentContext = parentContext;
    options.makeCurrentContext = false;
    auto span = plainSpanFactory_->startSpan(@"FrozenFrame", options, BSGTriStateNo, @{}, @[]);
    [span endWithAbsoluteTime:endTime];
}

void
SpanLifecycleHandlerImpl::reprocessEarlySpans() noexcept {
    // Up until now nothing was configured, so all early spans have been kept.
    // Now that configuration is complete, force-drain all early spans and re-process them.
    auto toReprocess = batch_->drain(true);
    for (BugsnagPerformanceSpan *span in toReprocess) {
        if (span.state != SpanStateEnded) {
            continue;
        }
        if (!sampler_->sampled(span)) {
            [span abortUnconditionally];
            continue;
        }
        [span forceMutate:^() {
            callOnSpanEndCallbacks(span);
        }];
        if (span.state == SpanStateAborted) {
            [span abortUnconditionally];
            continue;
        }

        batch_->add(span);
    }
}

void
SpanLifecycleHandlerImpl::abortAllOpenSpans() noexcept {
    store_->performActionAndClearOpenSpans(^(BugsnagPerformanceSpan *span) {
        [span abortIfOpen];
    });
}

void
SpanLifecycleHandlerImpl::processClosedSpan(BugsnagPerformanceSpan *span) noexcept {
    @synchronized (span) {
        for (BugsnagPerformanceSpanCondition *condition in span.conditionsToEndOnClose) {
            [condition closeWithEndTime:span.endTime];
        }
    }

    store_->removeSpan(span);

    if(span.state == SpanStateAborted) {
        return;
    }

    if (!sampler_->sampled(span)) {
        [span abortUnconditionally];
        return;
    }

    if (span != nil && span.state == SpanStateEnded) {
        [span forceMutate:^{
            callOnSpanEndCallbacks(span);
        }];
        if (span.state == SpanStateAborted) {
            return;
        }
    }
    
    if (shouldInstrumentRendering(span)) {
        processFrameMetrics(span);
    }

    batch_->add(span);
}
