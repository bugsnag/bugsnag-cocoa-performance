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

using namespace bugsnag;

Tracer::Tracer(std::shared_ptr<SpanStackingHandler> spanStackingHandler,
               std::shared_ptr<Sampler> sampler,
               std::shared_ptr<Batch> batch,
               FrameMetricsCollector *frameMetricsCollector,
               void (^onSpanStarted)()) noexcept
: spanStackingHandler_(spanStackingHandler)
, sampler_(sampler)
, prewarmSpans_([NSMutableArray new])
, potentiallyOpenSpans_(std::make_shared<WeakSpansList>())
, batch_(batch)
, frameMetricsCollector_(frameMetricsCollector)
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
        span.isMutable = true;
        [span updateSamplingProbability:sampler_->getProbability()];
        callOnSpanEndCallbacks(span);
        span.isMutable = false;
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
Tracer::startSpan(NSString *name, SpanOptions options, BSGFirstClass defaultFirstClass) noexcept {
    BSGLogDebug(@"Tracer::startSpan(%@, opts, %d)", name, defaultFirstClass);
    __block auto blockThis = this;
    auto parentSpan = options.parentContext;
    if (parentSpan == nil) {
        BSGLogTrace(@"Tracer::startSpan: No parent specified; using current span");
        parentSpan = spanStackingHandler_->currentSpan();
    }
    auto traceId = parentSpan.traceId;
    if (traceId.value == 0) {
        BSGLogTrace(@"Tracer::startSpan: No parent traceId; generating one");
        traceId = IdGenerator::generateTraceId();
    }
    BSGFirstClass firstClass = options.firstClass;
    if (firstClass == BSGFirstClassUnset) {
        BSGLogTrace(@"Tracer::startSpan: firstClass not specified; using default of %d", defaultFirstClass);
        firstClass = defaultFirstClass;
    }
    auto spanId = IdGenerator::generateSpanId();
    BugsnagPerformanceSpan *span = [[BugsnagPerformanceSpan alloc] initWithName:name
                                                                        traceId:traceId
                                                                         spanId:spanId
                                                                       parentId:parentSpan.spanId
                                                                      startTime:options.startTime
                                                                     firstClass:firstClass
                                                            attributeCountLimit:attributeCountLimit_
                                                            instrumentRendering: options.instrumentRendering
                                                                   onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull endedSpan) {
        blockThis->onSpanClosed(endedSpan);
    }];
    if (shouldInstrumentRendering(span)) {
        span.startFramerateSnapshot = [frameMetricsCollector_ currentSnapshot];
    }
    if (options.makeCurrentContext) {
        BSGLogTrace(@"Tracer::startSpan: Making current context");
        spanStackingHandler_->push(span);
    }
    [span internalSetMultipleAttributes:SpanAttributes::get()];
    potentiallyOpenSpans_->add(span);
    onSpanStarted_();
    return span;
}

void Tracer::onSpanClosed(BugsnagPerformanceSpan *span) {
    BSGLogTrace(@"Tracer::onSpanClosed: for span %@", span.name);
    
    if (shouldInstrumentRendering(span)) {
        span.endFramerateSnapshot = [frameMetricsCollector_ currentSnapshot];
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

    [span updateSamplingProbability:sampler_->getProbability()];

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

void Tracer::callOnSpanEndCallbacks(BugsnagPerformanceSpan *span) {
    if(span == nil) {
        return;
    }
    if (span.state != SpanStateEnded) {
        BSGLogDebug(@"Tracer::callOnSpanEndCallbacks: span %@ has state %d, so ignoring", span.name, span.state);
        return;
    }

    CFAbsoluteTime callbacksStartTime = CFAbsoluteTimeGetCurrent();
    for (BugsnagPerformanceSpanEndCallback callback: onSpanEndCallbacks_) {
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
    return startSpan(name, options, BSGFirstClassUnset);
}

BugsnagPerformanceSpan *
Tracer::startCustomSpan(NSString *name,
                        SpanOptions options) noexcept {
    return startSpan(name, options, BSGFirstClassYes);
}

BugsnagPerformanceSpan *
Tracer::startViewLoadSpan(BugsnagPerformanceViewType viewType,
                          NSString *className,
                          SpanOptions options) noexcept {
    NSString *type = getBugsnagPerformanceViewTypeName(viewType);
    onViewLoadSpanStarted_(className);
    NSString *name = [NSString stringWithFormat:@"[ViewLoad/%@]/%@", type, className];
    if (options.firstClass == BSGFirstClassUnset) {
        if (spanStackingHandler_->hasSpanWithAttribute(@"bugsnag.span.category", @"view_load")) {
            options.firstClass = BSGFirstClassNo;
        }
    }
    auto span = startSpan(name, options, BSGFirstClassYes);
    if (willDiscardPrewarmSpans_) {
        markPrewarmSpan(span);
    }
    return span;
}

BugsnagPerformanceSpan *
Tracer::startNetworkSpan(NSString *httpMethod, SpanOptions options) noexcept {
    auto name = [NSString stringWithFormat:@"[HTTP/%@]", httpMethod];
    return startSpan(name, options, BSGFirstClassUnset);
}

BugsnagPerformanceSpan *
Tracer::startViewLoadPhaseSpan(NSString *className,
                               NSString *phase,
                               BugsnagPerformanceSpanContext *parentContext) noexcept {
    NSString *name = [NSString stringWithFormat:@"[ViewLoadPhase/%@]/%@", phase, className];
    SpanOptions options;
    options.parentContext = parentContext;
    auto span = startSpan(name, options, BSGFirstClassUnset);
    if (willDiscardPrewarmSpans_) {
        markPrewarmSpan(span);
    }
    return span;
}

void Tracer::cancelQueuedSpan(BugsnagPerformanceSpan *span) noexcept {
    BSGLogTrace(@"Tracer::cancelQueuedSpan(%@)", span.name);
    if (span) {
        [span abortIfOpen];
        batch_->removeSpan(span.traceId, span.spanId);
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
    auto span = startSpan(@"FrozenFrame", options, BSGFirstClassNo);
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
    switch (span.instrumentRendering) {
        case BSGInstrumentRenderingYes:
            return autoInstrumentRendering_;
        case BSGInstrumentRenderingNo:
            return false;
        case BSGInstrumentRenderingUnset:
            return autoInstrumentRendering_ &&
            !span.wasStartOrEndTimeProvided && 
            span.firstClass == BSGFirstClassYes;
    }
}
