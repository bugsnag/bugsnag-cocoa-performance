//
//  Tracer.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "Tracer.h"

#import "ResourceAttributes.h"
#import "SpanAttributes.h"
#import "SpanContextStack.h"
#import "Utils.h"
#import "BugsnagPerformanceSpan+Private.h"
#import "Instrumentation/NetworkInstrumentation.h"
#import "Instrumentation/ViewLoadInstrumentation.h"
#import "BugsnagPerformanceLibrary.h"

using namespace bugsnag;

Tracer::Tracer(SpanContextStack *spanContextStack,
               std::shared_ptr<Sampler> sampler,
               std::shared_ptr<Batch> batch,
               void (^onSpanStarted)(),
               std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) noexcept
: spanContextStack_(spanContextStack)
, sampler_(sampler)
, batch_(batch)
, onSpanStarted_(onSpanStarted)
, spanAttributesProvider_(spanAttributesProvider)
{}

void
Tracer::configure(BugsnagPerformanceConfiguration *config) noexcept {
    configuration = config;
}

void
Tracer::start() noexcept {
    // Up until now the sampler was unconfigured and sampling at 1.0 (keep everything).
    // Now that the sampler has been configured, re-sample everything.
    batch_->allowDrain();
    auto unsampledBatch = batch_->drain();
    for (auto spanData: *unsampledBatch) {
        tryAddSpanToBatch(spanData);
    }

    if (configuration.autoInstrumentViewControllers) {
        viewLoadInstrumentation_ = std::make_unique<ViewLoadInstrumentation>(*this, configuration.viewControllerInstrumentationCallback);
        viewLoadInstrumentation_->start();
    }
    
    if (configuration.autoInstrumentNetwork) {
        networkInstrumentation_ = std::make_unique<NetworkInstrumentation>(*this, configuration.endpoint);
        networkInstrumentation_->start();
    }
}

BugsnagPerformanceSpan *
Tracer::startSpan(NSString *name, SpanOptions options, BSGFirstClass defaultFirstClass) noexcept {
    __block auto blockThis = this;
    auto currentContext = spanContextStack_.context;
    auto traceId = currentContext.traceId;
    if (traceId.value == 0) {
        traceId = IdGenerator::generateTraceId();
    }
    auto parentSpanId = options.parentContext.spanId;
    if (parentSpanId == 0) {
        parentSpanId = currentContext.spanId;
    }
    BSGFirstClass firstClass = options.firstClass;
    if (firstClass == BSGFirstClassUnset) {
        firstClass = defaultFirstClass;
    }
    auto spanId = IdGenerator::generateSpanId();
    auto span = [[BugsnagPerformanceSpan alloc] initWithSpan:std::make_unique<Span>(std::make_shared<SpanData>(name,
                                                              traceId,
                                                              spanId,
                                                              parentSpanId,
                                                              options.startTime,
                                                              firstClass),
                                       ^void(std::shared_ptr<SpanData> spanData) {
        blockThis->tryAddSpanToBatch(spanData);
    })];
    if (options.makeContextCurrent) {
        [spanContextStack_ push:span];
    }
    [span addAttributes:SpanAttributes::get()];
    if (onSpanStarted_) {
        onSpanStarted_();
    }
    return span;
}

void Tracer::tryAddSpanToBatch(std::shared_ptr<SpanData> spanData) {
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
    NSString *type;
    switch (viewType) {
        case BugsnagPerformanceViewTypeSwiftUI: type = @"SwiftUI"; break;
        case BugsnagPerformanceViewTypeUIKit:   type = @"UIKit"; break;
        default:                                type = @"?"; break;
    }
    onViewLoadSpanStarted_(className);
    NSString *name = [NSString stringWithFormat:@"[ViewLoad/%@]/%@", type, className];
    if (options.firstClass == BSGFirstClassUnset) {
        if ([spanContextStack_ hasSpanWithAttribute:@"bugsnag.span.category" value:@"view_load"]) {
            options.firstClass = BSGFirstClassNo;
        }
    }
    auto span = startSpan(name, options, BSGFirstClassYes);
    [span addAttributes:@{
        @"bugsnag.span.category": @"view_load",
        @"bugsnag.view.name": className,
        @"bugsnag.view.type": type
    }];
    return span;
}

void
Tracer::reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept {
    auto interval = metrics.taskInterval;

    auto name = [NSString stringWithFormat:@"[HTTP/%@]", task.originalRequest.HTTPMethod];
    SpanOptions options;
    options.startTime = dateToAbsoluteTime(interval.startDate);
    auto span = startSpan(name, options, BSGFirstClassUnset);

    [span addAttributes:spanAttributesProvider_->networkSpanAttributes(task, metrics)];

    [span endWithEndTime:interval.endDate];
}

void Tracer::cancelQueuedSpan(BugsnagPerformanceSpan *span) noexcept {
    if (span) {
        batch_->removeSpan(span.traceId, span.spanId);
    }
}
