//
//  Tracer.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "Tracer.h"

#import "BatchSpanProcessor.h"
#import "Instrumentation/AppStartupInstrumentation.h"
#import "Instrumentation/ViewLoadInstrumentation.h"
#import "Instrumentation/NetworkInstrumentation.h"
#import "OtlpTraceExporter.h"
#import "Sampler.h"
#import "Span.h"

using namespace bugsnag;

Tracer::Tracer() noexcept
: sampler_(std::make_shared<Sampler>(1.0))
, spanProcessor_(std::make_shared<BatchSpanProcessor>(sampler_))
{}

void
Tracer::start(BugsnagPerformanceConfiguration *configuration) noexcept {
    auto serviceName = NSBundle.mainBundle.bundleIdentifier ?: NSProcessInfo.processInfo.processName;
    auto resourceAttributes = @{
        @"service.name": serviceName,
        @"telemetry.sdk.name": @"bugsnag.performance.cocoa",
        @"telemetry.sdk.version": @"0.0",
    };
    
    sampler_->setFallbackProbability(configuration.samplingProbability);
    
    if (configuration.endpoint) {
        auto exporter = std::make_shared<OtlpTraceExporter>(configuration.endpoint, resourceAttributes);
        dynamic_cast<BatchSpanProcessor *>(spanProcessor_.get())->setSpanExporter(exporter);
    }
    
    if (configuration.autoInstrumentAppStarts) {
        appStartupInstrumentation_ = std::make_unique<AppStartupInstrumentation>(*this);
        appStartupInstrumentation_->start();
    }
    
    if (configuration.autoInstrumentViewControllers) {
        viewLoadInstrumentation_ = std::make_unique<ViewLoadInstrumentation>(*this, configuration.viewControllerInstrumentationCallback);
        viewLoadInstrumentation_->start();
    }
    
    if (configuration.autoInstrumentNetwork) {
        NSString *baseEndpoint = configuration.endpoint.absoluteString ?: @"";
        networkInstrumentation_ = std::make_unique<NetworkInstrumentation>(*this, baseEndpoint);
        networkInstrumentation_->start();
    }
}

std::unique_ptr<Span>
Tracer::startSpan(NSString *name, CFAbsoluteTime startTime) noexcept {
    return std::make_unique<Span>(std::make_unique<SpanData>(name, startTime), spanProcessor_);
}

std::unique_ptr<class Span>
Tracer::startViewLoadedSpan(BugsnagPerformanceViewType viewType,
                            NSString *className,
                            CFAbsoluteTime startTime) noexcept {
    NSString *type;
    switch (viewType) {
        case BugsnagPerformanceViewTypeSwiftUI: type = @"SwiftUI"; break;
        case BugsnagPerformanceViewTypeUIKit:   type = @"UIKit"; break;
        default:                                type = @"?"; break;
    }
    NSString *name = [NSString stringWithFormat:@"ViewLoaded/%@/%@", type, className];
    auto span = startSpan(name, startTime);
    span->addAttributes(@{
        @"bugsnag.span_category": @"view_load",
        @"bugsnag.view_type": type
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

static void addNonNull(NSMutableDictionary *dict, NSString *key, NSObject *value) {
    if (value != nil) {
        dict[key] = value;
    }
}

static void addNonZero(NSMutableDictionary *dict, NSString *key, NSNumber *value) {
    if (value.floatValue != 0) {
        dict[key] = value;
    }
}

void
Tracer::reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept {
    if (![task.response isKindOfClass:[NSHTTPURLResponse class]]) {
        return;
    }

    auto interval = metrics.taskInterval;
    auto name = [NSString stringWithFormat:@"HTTP/%@", task.originalRequest.HTTPMethod];
    auto httpResponse = (NSHTTPURLResponse *)task.response;

    auto span = startSpan(name, interval.startDate.timeIntervalSinceReferenceDate);

    auto attributes = [NSMutableDictionary new];
    attributes[@"bugsnag.span_category"] = @"network";
    addNonNull(attributes, @"http.method", task.originalRequest.HTTPMethod);
    addNonNull(attributes, @"http.url", task.originalRequest.URL.absoluteString);
    addNonZero(attributes, @"http.status_code", @(httpResponse.statusCode));
    addNonNull(attributes, @"http.flavor", getHTTPFlavour(metrics));
    addNonZero(attributes, @"http.request_content_length", @(task.countOfBytesSent));
    addNonZero(attributes, @"http.response_content_length", @(task.countOfBytesReceived));
    addNonNull(attributes, @"net.host.connection.type", getConnectionType(task, metrics));
    span->addAttributes(attributes);

    span->end(interval.endDate.timeIntervalSinceReferenceDate);
}
