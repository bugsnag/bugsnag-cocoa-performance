//
//  Tracer.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "Tracer.h"

#import "SpanAttributes.h"
#import "Utils.h"
#import "BugsnagPerformanceSpan+Private.h"
#import "Instrumentation/NetworkInstrumentation.h"
#import "Instrumentation/ViewLoadInstrumentation.h"
#import "BugsnagPerformanceLibrary.h"
#import "FrameRateMetrics/FrameMetricsCollector.h"
#import <algorithm>

using namespace bugsnag;

Tracer::Tracer(std::shared_ptr<SpanStackingHandler> spanStackingHandler,
               std::shared_ptr<Sampler> sampler,
               std::shared_ptr<Batch> batch,
               FrameMetricsCollector *frameMetricsCollector,
               std::shared_ptr<ConditionTimeoutExecutor> conditionTimeoutExecutor,
               std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
               BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> *onSpanStartCallbacks,
               BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> *onSpanEndCallbacks,
               void (^onSpanStarted)()) noexcept
: spanStackingHandler_(spanStackingHandler)
, sampler_(sampler)
, prewarmSpans_([NSMutableArray new])
, blockedSpans_([NSMutableArray new])
, potentiallyOpenSpans_(std::make_shared<WeakSpansList>())
, batch_(batch)
, frameMetricsCollector_(frameMetricsCollector)
, conditionTimeoutExecutor_(conditionTimeoutExecutor)
, spanAttributesProvider_(spanAttributesProvider)
, onSpanStartCallbacks_(onSpanStartCallbacks)
, onSpanEndCallbacks_(onSpanEndCallbacks)
, onSpanStarted_(onSpanStarted)
{}

void
Tracer::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    willDiscardPrewarmSpans_ = config.appWasLaunchedPreWarmed;
}

void
Tracer::preStartSetup() noexcept {
    BSGLogDebug(@"Tracer::preStartSetup()");
    reprocessEarlySpans();
}

void Tracer::reprocessEarlySpans(void) {
    BSGLogDebug(@"Tracer::reprocessEarlySpans()");
    // Up until now nothing was configured, so all early spans have been kept.
    // Now that configuration is complete, force-drain all early spans and re-process them.
    auto toReprocess = batch_->drain(true);
    BSGLogDebug(@"Tracer::reprocessEarlySpans: Reprocessing %zu early spans", toReprocess.count);
    for (BugsnagPerformanceSpan *span in toReprocess) {
        BSGLogDebug(@"Tracer::reprocessEarlySpans: Try to re-add span (%@) to batch", span.name);
        if (span.state != SpanStateEnded) {
            BSGLogDebug(@"Tracer::reprocessEarlySpans: span %@ has state %d, so ignoring", span.name, span.state);
            continue;
        }
        if (!sampler_->sampled(span)) {
            BSGLogDebug(@"Tracer::reprocessEarlySpans: span %@ was not sampled (P=%f), so dropping", span.name, sampler_->getProbability());
            [span abortUnconditionally];
            continue;
        }
        [span forceMutate:^() {
            callOnSpanEndCallbacks(span);
        }];
        if (span.state == SpanStateAborted) {
            BSGLogDebug(@"Tracer::reprocessEarlySpans: span %@ was rejected in the OnEnd callbacks, so dropping", span.name);
            [span abortUnconditionally];
            continue;
        }

        batch_->add(span);
    }
}

void
Tracer::abortAllOpenSpans() noexcept {
    BSGLogDebug(@"Tracer::abortAllOpenSpans()");
    potentiallyOpenSpans_->abortAllOpen();
}

void
Tracer::sweep() noexcept {
    BSGLogDebug(@"Tracer::sweep()");
    constexpr unsigned minEntriesBeforeCompacting = 10000;
    if (potentiallyOpenSpans_->count() >= minEntriesBeforeCompacting) {
        potentiallyOpenSpans_->compact();
    }
}

BugsnagPerformanceSpan *
Tracer::startSpan(NSString *name, SpanOptions options, BSGTriState defaultFirstClass) noexcept {
    BSGLogDebug(@"Tracer::startSpan(%@, opts, %d)", name, defaultFirstClass);
    __block auto blockThis = this;
    auto parentSpan = options.parentContext;
    if (parentSpan == nil) {
        BSGLogTrace(@"Tracer::startSpan: No parent specified; using current span");
        parentSpan = spanStackingHandler_->currentSpan();
    }

    TraceId traceId = { .hi = parentSpan.traceIdHi, .lo = parentSpan.traceIdLo };
    if (traceId.value == 0) {
        BSGLogTrace(@"Tracer::startSpan: No parent traceId; generating one");
        traceId = IdGenerator::generateTraceId();
    }
    BSGTriState firstClass = options.firstClass;
    if (firstClass == BSGTriStateUnset) {
        BSGLogTrace(@"Tracer::startSpan: firstClass not specified; using default of %d", defaultFirstClass);
        firstClass = defaultFirstClass;
    }
    auto spanId = IdGenerator::generateSpanId();
    auto onSpanEndSet = ^(BugsnagPerformanceSpan * _Nonnull endedSpan) {
        blockThis->onSpanEndSet(endedSpan);
    };
    auto onSpanClosed = ^(BugsnagPerformanceSpan * _Nonnull endedSpan) {
        if (!endedSpan.isBlocked) {
            blockThis->onSpanClosed(endedSpan);
        } else {
            @synchronized (this->blockedSpans_) {
                [blockedSpans_ addObject:endedSpan];
            }
        }
    };
    auto onSpanBlocked = ^BugsnagPerformanceSpanCondition * _Nullable(BugsnagPerformanceSpan * _Nonnull blockedSpan, NSTimeInterval timeout) {
        return blockThis->onSpanBlocked(blockedSpan, timeout);
    };

    BugsnagPerformanceSpan *span = [[BugsnagPerformanceSpan alloc] initWithName:name
                                                                        traceId:traceId
                                                                         spanId:spanId
                                                                       parentId:parentSpan.spanId
                                                                      startTime:options.startTime
                                                                     firstClass:firstClass
                                                            samplingProbability:sampler_->getProbability()
                                                            attributeCountLimit:attributeCountLimit_
                                                                 metricsOptions:options.metricsOptions
                                                                   onSpanEndSet:onSpanEndSet
                                                                   onSpanClosed:onSpanClosed
                                                                  onSpanBlocked:onSpanBlocked];
    if (shouldInstrumentRendering(span)) {
        span.startFramerateSnapshot = [frameMetricsCollector_ currentSnapshot];
    }
    if (options.makeCurrentContext) {
        BSGLogTrace(@"Tracer::startSpan: Making current context");
        spanStackingHandler_->push(span);
    }
    [span internalSetMultipleAttributes:SpanAttributes::get()];
    potentiallyOpenSpans_->add(span);
    
    callOnSpanStartCallbacks(span);
    
    onSpanStarted_();
    return span;
}

void Tracer::onSpanEndSet(BugsnagPerformanceSpan *span) {
    BSGLogTrace(@"Tracer::onSpanEndSet: for span %@", span.name);

    if (shouldInstrumentRendering(span)) {
        span.endFramerateSnapshot = [frameMetricsCollector_ currentSnapshot];
    }
}

void Tracer::onSpanClosed(BugsnagPerformanceSpan *span) {
    BSGLogTrace(@"Tracer::onSpanClosed: for span %@", span.name);
    
    @synchronized (span) {
        for (BugsnagPerformanceSpanCondition *condtion in span.assignedConditions) {
            [condtion closeWithEndTime:span.endTime];
        }
    }

    spanStackingHandler_->onSpanClosed(span.spanId);

    if(span.state == SpanStateAborted) {
        BSGLogTrace(@"Tracer::onSpanClosed: span %@ has been aborted, so ignoring", span.name);
        return;
    }

    if (!sampler_->sampled(span)) {
        BSGLogTrace(@"Tracer::onSpanClosed: span %@ was not sampled (P=%f), so dropping", span.name, sampler_->getProbability());
        [span abortUnconditionally];
        return;
    }

    if (span != nil && span.state == SpanStateEnded) {
        callOnSpanEndCallbacks(span);
        if (span.state == SpanStateAborted) {
            BSGLogTrace(@"Tracer::onSpanClosed: span %@ was rejected in the OnEnd callbacks, so dropping", span.name);
            return;
        }
    }
    
    if (shouldInstrumentRendering(span)) {
        BSGLogTrace(@"Tracer::onSpanClosed: Processing framerate metrics for span %@", span.name);
        processFrameMetrics(span);
    }

    BSGLogTrace(@"Tracer::onSpanClosed: Adding span %@ to batch", span.name);
    batch_->add(span);
}

BugsnagPerformanceSpanCondition *Tracer::onSpanBlocked(BugsnagPerformanceSpan *span, NSTimeInterval timeout) {
    if(span == nil || timeout <= 0) {
        return nil;
    }
    if (span.state != SpanStateOpen) {
        BSGLogDebug(@"Tracer::onSpanBlocked: span %@ has state %d, so ignoring", span.name, span.state);
        return nil;
    }
    BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:span onClosedCallback:^(BugsnagPerformanceSpanCondition *c, CFAbsoluteTime endTime) {
        __strong BugsnagPerformanceSpan *strongSpan = c.span;
        if (strongSpan.state == SpanStateEnded) {
            [strongSpan markEndAbsoluteTime:endTime];
        }
    } onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *c) {
        __strong BugsnagPerformanceSpan *strongSpan = c.span;
        @synchronized (this->blockedSpans_) {
            this->conditionTimeoutExecutor_->cancelTimeout(c);
        }
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
            BSGLogTrace(@"Tracer::onSpanBlocked: Processing unblocked span %@", span.name);
            @synchronized (this->blockedSpans_) {
                [this->blockedSpans_ removeObject:strongSpan];
                this->conditionTimeoutExecutor_->cancelTimeout(c);
            }
            this->onSpanClosed(strongSpan);
        }
    }];
    this->conditionTimeoutExecutor_->sheduleTimeout(condition, timeout);
    BSGLogTrace(@"Tracer::onSpanBlocked: Blocked span %@ with timeout %f", span.name, timeout);
    return condition;
}

void Tracer::callOnSpanStartCallbacks(BugsnagPerformanceSpan *span) {
    if(span == nil) {
        return;
    }

    for (BugsnagPerformanceSpanStartCallback callback: [onSpanStartCallbacks_ objects]) {
        @try {
            callback(span);
        } @catch(NSException *e) {
            BSGLogError(@"Tracer::callOnSpanStartCallbacks: span onStart callback threw exception: %@", e);
        }
    }
}

void Tracer::callOnSpanEndCallbacks(BugsnagPerformanceSpan *span) {
    if(span == nil) {
        return;
    }
    if (span.state != SpanStateEnded) {
        BSGLogDebug(@"Tracer::callOnSpanEndCallbacks: span %@ has state %d, so ignoring", span.name, span.state);
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
            BSGLogDebug(@"Tracer::callOnSpanEndCallbacks: span %@ OnEnd callback returned false. Dropping...", span.name);
            [span abortUnconditionally];
            return;
        }
    }
    CFAbsoluteTime callbacksEndTime = CFAbsoluteTimeGetCurrent();
    BSGLogDebug(@"Tracer::callOnSpanEndCallbacks: Adding span %@ to batch", span.name);
    [span internalSetAttribute:@"bugsnag.span.callbacks_duration" withValue:@(intervalToNanoseconds(callbacksEndTime - callbacksStartTime))];
}

void Tracer::processFrameMetrics(BugsnagPerformanceSpan *span) noexcept {
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
    [span setAttribute:@"bugsnag.rendering.total_frames" withValue:@(mergedSnapshot.totalFrames)];
    [span setAttribute:@"bugsnag.rendering.slow_frames" withValue:@(mergedSnapshot.totalSlowFrames)];
    [span setAttribute:@"bugsnag.rendering.frozen_frames" withValue:@(mergedSnapshot.totalFrozenFrames)];
    
    auto frozenFrame = mergedSnapshot.firstFrozenFrame;
    while (frozenFrame != nil) {
        createFrozenFrameSpan(frozenFrame.startTime, frozenFrame.endTime, span);
        frozenFrame = frozenFrame != mergedSnapshot.lastFrozenFrame ? frozenFrame.next : nil;
    }
}

BugsnagPerformanceSpan *
Tracer::startAppStartSpan(NSString *name,
                        SpanOptions options) noexcept {
    return startSpan(name, options, BSGTriStateUnset);
}

BugsnagPerformanceSpan *
Tracer::startCustomSpan(NSString *name,
                        SpanOptions options) noexcept {
    return startSpan(name, options, BSGTriStateYes);
}

BugsnagPerformanceSpan *
Tracer::startViewLoadSpan(BugsnagPerformanceViewType viewType,
                          NSString *className,
                          SpanOptions options) noexcept {
    NSString *type = getBugsnagPerformanceViewTypeName(viewType);
    BugsnagPerformanceSpanCondition *appStartupCondition = nil;
    if (options.parentContext == nil && getAppStartupInstrumentationState_ != nil) {
        AppStartupInstrumentationState *appStartupState = getAppStartupInstrumentationState_();
        if (appStartupState.isInProgress && !appStartupState.hasFirstView) {
            options.parentContext = appStartupState.uiInitSpan;
            appStartupCondition = [appStartupState.uiInitSpan blockWithTimeout:0.1];
        }
    }
    onViewLoadSpanStarted_(className);
    NSString *name = [NSString stringWithFormat:@"[ViewLoad/%@]/%@", type, className];
    if (options.firstClass == BSGTriStateUnset) {
        if (spanStackingHandler_->hasSpanWithAttribute(@"bugsnag.span.category", @"view_load")) {
            options.firstClass = BSGTriStateNo;
        }
    }
    auto span = startSpan(name, options, BSGTriStateYes);
    if (willDiscardPrewarmSpans_) {
        markPrewarmSpan(span);
    }
    if (appStartupCondition) {
        [span assignCondition:appStartupCondition];
    }
    return span;
}

BugsnagPerformanceSpan *
Tracer::startNetworkSpan(NSString *httpMethod, SpanOptions options) noexcept {
    auto name = [NSString stringWithFormat:@"[HTTP/%@]", httpMethod ?: @"unknown"];
    auto span = startSpan(name, options, BSGTriStateUnset);
    span.kind = SPAN_KIND_CLIENT;
    [span internalSetMultipleAttributes:spanAttributesProvider_->initialNetworkSpanAttributes()];
    return span;
}

BugsnagPerformanceSpan *
Tracer::startViewLoadPhaseSpan(NSString *className,
                               NSString *phase,
                               BugsnagPerformanceSpanContext *parentContext) noexcept {
    NSString *name = [NSString stringWithFormat:@"[ViewLoadPhase/%@]/%@", phase, className];
    SpanOptions options;
    options.parentContext = parentContext;
    auto span = startSpan(name, options, BSGTriStateUnset);
    if (willDiscardPrewarmSpans_) {
        markPrewarmSpan(span);
    }
    return span;
}

void Tracer::cancelQueuedSpan(BugsnagPerformanceSpan *span) noexcept {
    BSGLogTrace(@"Tracer::cancelQueuedSpan(%@)", span.name);
    if (span) {
        [span abortIfOpen];
        batch_->removeSpan(span.traceIdHi, span.traceIdLo, span.spanId);
    }
}

void Tracer::markPrewarmSpan(BugsnagPerformanceSpan *span) noexcept {
    BSGLogTrace(@"Tracer::markPrewarmSpan(%@)", span.name);
    std::lock_guard<std::mutex> guard(prewarmSpansMutex_);
    if (willDiscardPrewarmSpans_) {
        [prewarmSpans_ addObject:span];
    }
}

void
Tracer::createFrozenFrameSpan(NSTimeInterval startTime,
                              NSTimeInterval endTime,
                              BugsnagPerformanceSpanContext *parentContext) noexcept {
    SpanOptions options;
    options.startTime = startTime;
    options.parentContext = parentContext;
    options.makeCurrentContext = false;
    auto span = startSpan(@"FrozenFrame", options, BSGTriStateNo);
    [span endWithAbsoluteTime:endTime];
}

void
Tracer::onPrewarmPhaseEnded(void) noexcept {
    BSGLogDebug(@"Tracer::onPrewarmPhaseEnded()");
    std::lock_guard<std::mutex> guard(prewarmSpansMutex_);
    willDiscardPrewarmSpans_ = false;
    for (BugsnagPerformanceSpan *span: prewarmSpans_) {
        // Only cancel unfinished prewarm spans
        if (span.state == SpanStateOpen) {
            cancelQueuedSpan(span);
        }
    }
    [prewarmSpans_ removeAllObjects];
}

bool
Tracer::shouldInstrumentRendering(BugsnagPerformanceSpan *span) noexcept {
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
