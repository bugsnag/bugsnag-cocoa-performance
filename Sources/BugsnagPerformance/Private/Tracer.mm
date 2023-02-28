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

using namespace bugsnag;

Tracer::Tracer(std::shared_ptr<Sampler> sampler, std::shared_ptr<Batch> batch, void (^onSpanStarted)()) noexcept
: sampler_(sampler)
, batch_(batch)
, onSpanStarted_(onSpanStarted)
{}

void
Tracer::start(BugsnagPerformanceConfiguration *configuration) noexcept {
    if (configuration.autoInstrumentAppStarts) {
        appStartupInstrumentation_ = std::make_unique<AppStartupInstrumentation>(*this);
        appStartupInstrumentation_->start();
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

std::unique_ptr<Span>
Tracer::startSpan(NSString *name, SpanOptions options) noexcept {
    __block auto blockThis = this;
    auto currentContext = SpanContextStack.current.context;
    auto traceId = currentContext.traceId;
    if (traceId.value == 0) {
        traceId = IdGenerator::generateTraceId();
    }
    auto spanId = IdGenerator::generateSpanId();
    auto span = std::make_unique<Span>(std::make_unique<SpanData>(name,
                                                                  traceId,
                                                                  spanId,
                                                                  currentContext.spanId,
                                                                  options.startTime,
                                                                  options.isFirstClass),
                                       ^void(std::unique_ptr<SpanData> spanData) {
        blockThis->tryAddSpanToBatch(std::move(spanData));
    });
    span->addAttributes(SpanAttributes::get());
    if (onSpanStarted_) {
        onSpanStarted_();
    }
    return span;
}

void Tracer::tryAddSpanToBatch(std::unique_ptr<SpanData> spanData) {
    if (sampler_->sampled(*spanData)) {
        batch_->add(std::move(spanData));
    }
}

std::unique_ptr<class Span>
Tracer::startViewLoadSpan(BugsnagPerformanceViewType viewType,
                          NSString *className,
                          SpanOptions options) noexcept {
    NSString *type;
    switch (viewType) {
        case BugsnagPerformanceViewTypeSwiftUI: type = @"SwiftUI"; break;
        case BugsnagPerformanceViewTypeUIKit:   type = @"UIKit"; break;
        default:                                type = @"?"; break;
    }
    NSString *name = [NSString stringWithFormat:@"ViewLoad/%@/%@", type, className];
    auto span = startSpan(name, options);
    span->addAttributes(@{
        @"bugsnag.span.category": @"view_load",
        @"bugsnag.view.name": className,
        @"bugsnag.view.type": type
    });
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
    auto span = startSpan(name, defaultSpanOptionsForNetwork(dateToAbsoluteTime(interval.startDate)));

    auto attributes = [NSMutableDictionary new];
    attributes[@"bugsnag.span.category"] = @"network";
    attributes[@"http.flavor"] = getHTTPFlavour(metrics);
    attributes[@"http.method"] = task.originalRequest.HTTPMethod;
    attributes[@"http.status_code"] = httpResponse ? @(httpResponse.statusCode) : @0;
    attributes[@"http.url"] = task.originalRequest.URL.absoluteString;
    attributes[@"net.host.connection.type"] = getConnectionType(task, metrics);
    addNonZero(attributes, @"http.request_content_length", @(task.countOfBytesSent));
    addNonZero(attributes, @"http.response_content_length", @(task.countOfBytesReceived));
    span->addAttributes(attributes);

    span->end(dateToAbsoluteTime(interval.endDate));
}
