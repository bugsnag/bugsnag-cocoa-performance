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

static NSString *httpUrlAttributeKey = @"http.url";

using namespace bugsnag;

Tracer::Tracer(std::shared_ptr<SpanStackingHandler> spanStackingHandler,
               std::shared_ptr<Sampler> sampler,
               std::shared_ptr<Batch> batch,
               void (^onSpanStarted)()) noexcept
: spanStackingHandler_(spanStackingHandler)
, sampler_(sampler)
, earlyNetworkSpans_([NSMutableArray new])
, batch_(batch)
, onSpanStarted_(onSpanStarted)
{}

void
Tracer::configure(BugsnagPerformanceConfiguration *config) noexcept {
    auto networkRequestCallback = config.networkRequestCallback;
    if (networkRequestCallback != nullptr) {
        networkRequestCallback_ = networkRequestCallback;
    }
    endEarlySpansPhase();
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
    return startSpan(name, options, BSGFirstClassYes);
}

BugsnagPerformanceSpan *
Tracer::startNetworkSpan(NSURL *url, NSString *httpMethod, SpanOptions options) noexcept {
    auto info = [BugsnagPerformanceNetworkRequestInfo new];
    info.url = url;
    info = networkRequestCallback_(info);
    url = info.url;
    if (url == nil) {
        return nil;
    }

    auto name = [NSString stringWithFormat:@"[HTTP/%@]", httpMethod];
    auto span = startSpan(name, options, BSGFirstClassUnset);
    [span addAttribute:httpUrlAttributeKey withValue:(NSString *_Nonnull)url.absoluteString];
    if (isEarlySpansPhase_) {
        markEarlyNetworkSpan(span);
    }
    return span;
}

BugsnagPerformanceSpan *
Tracer::startViewLoadPhaseSpan(NSString *name,
                        SpanOptions options) noexcept {
    return startSpan(name, options, BSGFirstClassUnset);
}

void Tracer::cancelQueuedSpan(BugsnagPerformanceSpan *span) noexcept {
    if (span) {
        batch_->removeSpan(span.traceId, span.spanId);
    }
}

void Tracer::markEarlyNetworkSpan(BugsnagPerformanceSpan *span) noexcept {
    std::lock_guard<std::mutex> guard(earlySpansMutex_);
    if (isEarlySpansPhase_) {
        [earlyNetworkSpans_ addObject:span];
    }
}

void Tracer::endEarlySpansPhase() noexcept {
    std::lock_guard<std::mutex> guard(earlySpansMutex_);
    isEarlySpansPhase_ = false;
    for (BugsnagPerformanceSpan *span: earlyNetworkSpans_) {
        auto info = [BugsnagPerformanceNetworkRequestInfo new];
        NSString *urlString = [span getAttribute:httpUrlAttributeKey];
        info.url = [NSURL URLWithString:urlString];
        // We have to check again because the real callback might not have been set initially.
        info = networkRequestCallback_(info);
        if (info.url != nil) {
            [span addAttribute:httpUrlAttributeKey withValue:(NSString *_Nonnull)info.url.absoluteString];
        } else {
            cancelQueuedSpan(span);
        }
    }
    [earlyNetworkSpans_ removeAllObjects];
}
