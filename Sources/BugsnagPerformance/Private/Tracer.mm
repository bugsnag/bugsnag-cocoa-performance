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

using namespace bugsnag;

Tracer::Tracer(std::shared_ptr<SpanStackingHandler> spanStackingHandler,
               std::shared_ptr<Sampler> sampler,
               std::shared_ptr<Batch> batch,
               void (^onSpanStarted)()) noexcept
: spanStackingHandler_(spanStackingHandler)
, sampler_(sampler)
, prewarmSpans_([NSMutableArray new])
, potentiallyOpenSpans_(std::make_shared<WeakSpansList>())
, batch_(batch)
, onSpanStarted_(onSpanStarted)
{}

void
Tracer::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    willDiscardPrewarmSpans_ = config.appWasLaunchedPreWarmed;
}

void
Tracer::preStartSetup() noexcept {
    BSGLogDebug(@"Tracer::preStartSetup()");
    // Up until now nothing was configured, so all early spans have been kept.
    // Now that configuration is complete, force-drain all early spans and re-process them.
    auto toReprocess = batch_->drain(true);
    BSGLogDebug(@"Tracer::preStartSetup: initial unsampled batch with %zu items", unsampledBatch.count);
    for (BugsnagPerformanceSpan *span in toReprocess) {
        BSGLogDebug(@"Tracer::preStartSetup: Try to re-add span (%@) to batch", span.name);
        if (span.state != SpanStateEnded) {
            BSGLogDebug(@"Tracer::preStartSetup: span %@ has state %d, so ignoring", span.name, span.state);
            continue;
        }
        if (!sampler_->sampled(span)) {
            BSGLogDebug(@"Tracer::preStartSetup: span %@ was not sampled (P=%f), so dropping", span.name, sampler_->getProbability());
            [span abortUnconditionally];
            continue;
        }
        callOnSpanEndCallbacks(span);
        if (span.state == SpanStateAborted) {
            BSGLogDebug(@"Tracer::preStartSetup: span %@ was rejected in the OnEnd callbacks, so dropping", span.name);
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
                                                                    onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull endedSpan) {
        blockThis->onSpanClosed(endedSpan);
    }];
    if (options.makeCurrentContext) {
        BSGLogTrace(@"Tracer::startSpan: Making current context");
        spanStackingHandler_->push(span);
    }
    [span setMultipleAttributes:SpanAttributes::get()];
    potentiallyOpenSpans_->add(span);
    onSpanStarted_();
    return span;
}

void Tracer::onSpanClosed(BugsnagPerformanceSpan *span) {
    BSGLogTrace(@"Tracer::onSpanClosed: for span %@", span.name);

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

    BSGLogTrace(@"Tracer::onSpanClosed: Adding span %@ to batch", span.name);
    batch_->add(span);
}

void Tracer::callOnSpanEndCallbacks(BugsnagPerformanceSpan *span) {
    if(span == nil) {
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
    [span setAttribute:@"bugsnag.span.callbacks_duration" withValue:@(intervalToNanoseconds(callbacksEndTime - callbacksStartTime))];
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
