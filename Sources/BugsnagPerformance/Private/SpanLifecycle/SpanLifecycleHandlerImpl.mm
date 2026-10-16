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
    if (shouldSampleDiskIO(span) || shouldSampleDiskIOBeforeStart(span)) {
        [diskIOCollector_ onSpanStart:span];
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
    // Gated exactly like rendering: a span whose start or end time was
    // supplied by the caller reports a window that does not match the real
    // elapsed time between the start() and end() calls, so IOPS computed over
    // the real window would not describe the span. The start snapshot (if any)
    // is released when the span is final, in onSpanClosed/processClosedSpan.
    //
    // This may run more than once for a blocked span whose end time a span
    // condition later extends; each run recomputes over the current window.
    if (shouldSampleDiskIO(span)) {
        if (span.diskIOBaselineIsProcessStart) {
            [diskIOCollector_ onProcessStartSpan:span];
        }
        NSDictionary *diskAttributes = [diskIOCollector_ onSpanEnd:span];
        if (diskAttributes.count > 0) {
            [span forceMutate:^{
                [span internalSetMultipleAttributes:diskAttributes];
            }];
        }
    } else if (shouldSampleDiskIOBeforeStart(span)) {
        // A span that ends before start() (for example a custom span created in
        // didFinishLaunching before BugsnagPerformance.start): the end snapshot
        // must be taken now, but whether disk metrics are enabled is not known
        // until configure. Hold the result on the span; reprocessEarlySpans
        // attaches it only if enabledMetrics.disk is on.
        span.earlyDiskIOAttributes = [diskIOCollector_ onSpanEnd:span];
    }
    // Internal SDK bookkeeping that must happen as soon as the end time is set,
    // Before sampling or user on-span-end callbacks can discard the span.
    onSpanEndSet_(span);
}

void
SpanLifecycleHandlerImpl::onSpanClosed(BugsnagPerformanceSpan *span) noexcept {
    if (span.state == SpanStateAborted) {
        // Every abort path (abortOpenSpansOnBackground, abortIfOpen,
        // abortUnconditionally, the dealloc abort of a dropped open span)
        // arrives here via sendForProcessing, and a blocked span that aborts
        // never reaches processClosedSpan, so release the disk-IO start
        // snapshot here rather than further down.
        [diskIOCollector_ abandonSpan:span];
    }
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
    // Release any pending disk-IO start snapshot so the map does not grow
    // for spans that will never end (only -cancel reaches here).
    [diskIOCollector_ abandonSpan:span];
    batch_->removeSpan(span.traceIdHi, span.traceIdLo, span.spanId);
    onSpanDiscarded_(span);
    if (span.isBlocked) {
        store_->removeSpanFromBlocked(span);
    }
}

void
SpanLifecycleHandlerImpl::onAppEnteredBackground() noexcept {
    if (isStarted_) {
        abortOpenSpansOnBackground();
    }
}

#pragma mark Private

bool
SpanLifecycleHandlerImpl::shouldInstrumentRendering(BugsnagPerformanceSpan *span) noexcept {
    // Load once per call so every check below sees the same value, even if
    // configure() runs concurrently on another thread.
    const bool renderingEnabled = renderingMetricsEnabled_.load(std::memory_order_relaxed);
    switch (span.metricsOptions.rendering) {
        case BSGTriStateYes:
            return renderingEnabled;
        case BSGTriStateNo:
            return false;
        case BSGTriStateUnset:
            return renderingEnabled &&
            !span.wasStartOrEndTimeProvided &&
            span.firstClass == BSGTriStateYes;
    }
}

bool
SpanLifecycleHandlerImpl::shouldSampleDiskIO(BugsnagPerformanceSpan *span) noexcept {
    // After BugsnagPerformance.start(), disk I/O is collected only when the
    // user's configuration enables it. Spans that start before start() are
    // handled by shouldSampleDiskIOBeforeStart.
    if (!isStarted_ || !diskMetricsEnabled_.load(std::memory_order_relaxed)) {
        return false;
    }
    return isDiskIOEligible(span);
}

bool
SpanLifecycleHandlerImpl::shouldSampleDiskIOBeforeStart(BugsnagPerformanceSpan *span) noexcept {
    // Before start(), configure() has not applied the user's enabledMetrics yet,
    // so an eligible span's snapshots are taken speculatively (as rendering
    // metrics are): a custom span started during launch can only get its disk
    // IOPS if its start counters are read when it starts. The readings stay in
    // memory and are never attached or sent unless the SDK starts with
    // enabledMetrics.disk on (applyEarlyDiskIO); otherwise they are dropped.
    //
    // A span whose start time was supplied by the caller is excluded: a
    // snapshot taken now does not describe its window. This also keeps the
    // app-start span on its process-launch baseline (onProcessStartSpan).
    if (isStarted_ || span.wasStartOrEndTimeProvided) {
        return false;
    }
    return isDiskIOEligible(span);
}

void
SpanLifecycleHandlerImpl::applyEarlyDiskIO(BugsnagPerformanceSpan *span) noexcept {
    NSDictionary *attributes = span.earlyDiskIOAttributes;
    if (attributes == nil) {
        return;
    }
    span.earlyDiskIOAttributes = nil;
    // configure() has run: attach only if the user enabled disk metrics and the
    // span is still eligible (its end time was not supplied by the caller).
    if (!diskMetricsEnabled_.load(std::memory_order_relaxed) || !isDiskIOEligible(span) || attributes.count == 0) {
        return;
    }
    [span forceMutate:^{
        [span internalSetMultipleAttributes:attributes];
    }];
}

bool
SpanLifecycleHandlerImpl::isDiskIOEligible(BugsnagPerformanceSpan *span) noexcept {
    switch (span.metricsOptions.disk) {
        case BSGTriStateYes:
            return true;
        case BSGTriStateNo:
            return false;
        case BSGTriStateUnset:
            // Same rule as rendering: caller-supplied start/end times make the
            // real elapsed window meaningless for the span.
            return span.firstClass == BSGTriStateYes &&
                   !span.wasStartOrEndTimeProvided;
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
            span.earlyDiskIOAttributes = nil;
            [span abortUnconditionally];
            onSpanDiscarded_(span);
            continue;
        }
        // Before the user's callbacks, as for spans ending after start: the
        // disk IOPS of a span that ended before start() are attached now that
        // the configuration is known.
        applyEarlyDiskIO(span);
        [span forceMutate:^() {
            callOnSpanEndCallbacks(span);
        }];
        if (span.state == SpanStateAborted) {
            [span abortUnconditionally];
            onSpanDiscarded_(span);
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
SpanLifecycleHandlerImpl::abortOpenSpansOnBackground() noexcept {
    store_->performActionAndCompactOpenSpans(^(BugsnagPerformanceSpan *span) {
        if (!span.isAppSessionSpan) {
            [span abortIfOpen];
        }
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
    // The span is final from here on (its end time can no longer move), so
    // the disk-IO start snapshot is no longer needed whatever happens next.
    [diskIOCollector_ abandonSpan:span];

    if(span.state == SpanStateAborted) {
        onSpanDiscarded_(span);
        return;
    }

    if (!sampler_->sampled(span)) {
        [span abortUnconditionally];
        onSpanDiscarded_(span);
        return;
    }

    if (span != nil && span.state == SpanStateEnded) {
        [span forceMutate:^{
            callOnSpanEndCallbacks(span);
        }];
        if (span.state == SpanStateAborted) {
            onSpanDiscarded_(span);
            return;
        }
    }
    
    if (shouldInstrumentRendering(span)) {
        processFrameMetrics(span);
    }

    batch_->add(span);
}
