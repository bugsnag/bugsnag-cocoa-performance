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
Tracer::start() noexcept {
    // Up until now the sampler was unconfigured and sampling at 1.0 (keep everything).
    // Now that the sampler has been configured, re-sample everything.
    auto unsampledBatch = batch_->drain(true);
    for (auto spanData: *unsampledBatch) {
        trySampleAndAddSpanToBatch(spanData);
    }
}

void
Tracer::abortAllOpenSpans() noexcept {
    potentiallyOpenSpans_->abortAll();
}

void
Tracer::sweep() noexcept {
    constexpr unsigned minEntriesBeforeCompacting = 10000;
    if (potentiallyOpenSpans_->count() >= minEntriesBeforeCompacting) {
        potentiallyOpenSpans_->compact();
    }
}

BugsnagPerformanceSpan *
Tracer::startSpan(NSString *name, SpanOptions options, BSGFirstClass defaultFirstClass) noexcept {
    __block auto blockThis = this;
    auto parentSpan = options.parentContext;
    if (parentSpan == nil) {
        parentSpan = spanStackingHandler_->currentSpan();
    }
    auto traceId = parentSpan.traceId;
    if (traceId.value == 0) {
        traceId = IdGenerator::generateTraceId();
    }
    BSGFirstClass firstClass = options.firstClass;
    if (firstClass == BSGFirstClassUnset) {
        firstClass = defaultFirstClass;
    }
    auto spanId = IdGenerator::generateSpanId();
    auto span = [[BugsnagPerformanceSpan alloc] initWithSpan:std::make_unique<Span>(name,
                                                              traceId,
                                                              spanId,
                                                              parentSpan.spanId,
                                                              options.startTime,
                                                              firstClass,
                                       ^void(std::shared_ptr<SpanData> spanData) {
        blockThis->spanStackingHandler_->didEnd(spanData->spanId);
        blockThis->trySampleAndAddSpanToBatch(spanData);
    })];
    if (options.makeCurrentContext) {
        spanStackingHandler_->push(span);
    }
    [span addAttributes:SpanAttributes::get()];
    potentiallyOpenSpans_->add(span);
    onSpanStarted_();
    return span;
}

void Tracer::trySampleAndAddSpanToBatch(std::shared_ptr<SpanData> spanData) {
    if (sampler_->sampled(*spanData)) {
        batch_->add(spanData);
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
                               BugsnagPerformanceSpan *parentContext) noexcept {
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
    if (span) {
        [span abort];
        batch_->removeSpan(span.traceId, span.spanId);
    }
}

void Tracer::markPrewarmSpan(BugsnagPerformanceSpan *span) noexcept {
    std::lock_guard<std::mutex> guard(prewarmSpansMutex_);
    if (willDiscardPrewarmSpans_) {
        [prewarmSpans_ addObject:span];
    }
}

void
Tracer::onPrewarmPhaseEnded(void) noexcept {
    std::lock_guard<std::mutex> guard(prewarmSpansMutex_);
    willDiscardPrewarmSpans_ = false;
    for (BugsnagPerformanceSpan *span: prewarmSpans_) {
        // Only cancel unfinished prewarm spans
        if (span.isValid) {
            cancelQueuedSpan(span);
        }
    }
    [prewarmSpans_ removeAllObjects];
}
