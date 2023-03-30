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
#import "Instrumentation/AppStartupInstrumentation.h"
#import "Instrumentation/NetworkInstrumentation.h"
#import "Instrumentation/ViewLoadInstrumentation.h"

using namespace bugsnag;

Tracer::Tracer(std::shared_ptr<Sampler> sampler, std::shared_ptr<Batch> batch, void (^onSpanStarted)()) noexcept
: sampler_(sampler)
, batch_(batch)
, onSpanStarted_(onSpanStarted)
, appStartupInstrumentation_(AppStartupInstrumentation::sharedInstance())
{}

void
Tracer::start(BugsnagPerformanceConfiguration *configuration) noexcept {
    if (!configuration.autoInstrumentAppStarts) {
        appStartupInstrumentation_->disable();
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
    auto currentContext = SpanContextStack.current.context;
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
        [SpanContextStack.current push:span];
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
    appStartupInstrumentation_->didStartViewLoadSpan(className);
    NSString *name = [NSString stringWithFormat:@"ViewLoad/%@/%@", type, className];
    if (options.firstClass == BSGFirstClassUnset) {
        if ([SpanContextStack.current hasSpanWithAttribute:@"bugsnag.span.category" value:@"view_load"]) {
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

static NSString *getHTTPFlavour(NSURLSessionTaskMetrics *metrics) {
    if (metrics.transactionMetrics.count > 0) {
        NSString *protocolName = metrics.transactionMetrics[0].networkProtocolName;
        if ([protocolName isEqualToString:@"http/1.1"]) {
            return @"1.1";
        }
        if ([protocolName isEqualToString:@"h2"]) {
            return @"2.0";
        }
        if ([protocolName isEqualToString:@"h3"]) {
            return @"3.0";
        }
        if ([protocolName hasPrefix:@"spdy/"]) {
            return @"SPDY";
        }
    }
    return nil;
}

static NSString *getConnectionType(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) {
    if (task.error.code == NSURLErrorNotConnectedToInternet) {
        return @"unavailable";
    }
    if (@available(macos 10.15 , ios 13.0 , watchos 6.0 , tvos 13.0, *)) {
        if (metrics.transactionMetrics.count > 0 && metrics.transactionMetrics[0].cellular) {
            return @"cell";
        }
    }
    return @"wifi";
}

static void addNonZero(NSMutableDictionary *dict, NSString *key, NSNumber *value) {
    if (value.floatValue != 0) {
        dict[key] = value;
    }
}

void
Tracer::reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept {
    auto interval = metrics.taskInterval;
    auto httpResponse = BSGDynamicCast<NSHTTPURLResponse>(task.response);

    auto name = [NSString stringWithFormat:@"HTTP/%@", task.originalRequest.HTTPMethod];
    SpanOptions options;
    options.startTime = dateToAbsoluteTime(interval.startDate);
    auto span = startSpan(name, options, BSGFirstClassUnset);

    auto attributes = [NSMutableDictionary new];
    attributes[@"bugsnag.span.category"] = @"network";
    attributes[@"http.flavor"] = getHTTPFlavour(metrics);
    attributes[@"http.method"] = task.originalRequest.HTTPMethod;
    attributes[@"http.status_code"] = httpResponse ? @(httpResponse.statusCode) : @0;
    attributes[@"http.url"] = task.originalRequest.URL.absoluteString;
    attributes[@"net.host.connection.type"] = getConnectionType(task, metrics);
    addNonZero(attributes, @"http.request_content_length", @(task.countOfBytesSent));
    addNonZero(attributes, @"http.response_content_length", @(task.countOfBytesReceived));
    [span addAttributes:attributes];

    [span endWithEndTime:interval.endDate];
}

void Tracer::cancelQueuedSpan(BugsnagPerformanceSpan *span) noexcept {
    if (span) {
        batch_->removeSpan(span.traceId, span.spanId);
    }
}
