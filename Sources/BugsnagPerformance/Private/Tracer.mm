//
//  Tracer.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "Tracer.h"

#import "BatchSpanProcessor.h"
#import "Instrumentation/AppStartupInstrumentation.h"
#import "Instrumentation/NetworkInstrumentation.h"
#import "Instrumentation/ViewLoadInstrumentation.h"
#import "OtlpTraceExporter.h"
#import "OtlpUploader.h"
#import "Reachability.h"
#import "ResourceAttributes.h"
#import "Sampler.h"
#import "Span.h"
#import "SpanAttributes.h"
#import "Utils.h"

using namespace bugsnag;

Tracer::Tracer() noexcept
: sampler_(std::make_shared<Sampler>(1.0))
, spanProcessor_(std::make_shared<BatchSpanProcessor>(sampler_))
{}

void
Tracer::start(BugsnagPerformanceConfiguration *configuration) noexcept {
    auto resourceAttributes = ResourceAttributes(configuration).get();
    
    sampler_->setFallbackProbability(configuration.samplingProbability);
    
    if (auto url = [NSURL URLWithString:configuration.endpoint]) {
        auto uploader = std::make_shared<OtlpUploader>(url, configuration.apiKey, ^(double newProbability) {
            sampler_->setProbability(newProbability);
        });
        auto exporter = std::make_shared<OtlpTraceExporter>(resourceAttributes, uploader);
        dynamic_cast<BatchSpanProcessor *>(spanProcessor_.get())->setSpanExporter(exporter);
        Reachability::get().addCallback(^(Reachability::Connectivity connectivity) {
            switch (connectivity) {
                case Reachability::Cellular: case Reachability::Wifi:
                    exporter->notifyConnectivityReestablished();
                    break;
                case Reachability::Unknown: case Reachability::None:
                    break;
            }
        });
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
        networkInstrumentation_ = std::make_unique<NetworkInstrumentation>(*this, configuration.endpoint);
        networkInstrumentation_->start();
    }
}

std::unique_ptr<Span>
Tracer::startSpan(NSString *name, CFAbsoluteTime startTime) noexcept {
    auto span = std::make_unique<Span>(std::make_unique<SpanData>(name, startTime), spanProcessor_);
    span->addAttributes(SpanAttributes::get());
    return span;
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
    auto span = startSpan(name, interval.startDate.timeIntervalSinceReferenceDate);

    auto attributes = [NSMutableDictionary new];
    attributes[@"bugsnag.span_category"] = @"network";
    attributes[@"http.flavor"] = getHTTPFlavour(metrics);
    attributes[@"http.method"] = task.originalRequest.HTTPMethod;
    attributes[@"http.status_code"] = httpResponse ? @(httpResponse.statusCode) : @0;
    attributes[@"http.url"] = task.originalRequest.URL.absoluteString;
    attributes[@"net.host.connection.type"] = getConnectionType(task, metrics);
    addNonZero(attributes, @"http.request_content_length", @(task.countOfBytesSent));
    addNonZero(attributes, @"http.response_content_length", @(task.countOfBytesReceived));
    span->addAttributes(attributes);

    span->end(interval.endDate.timeIntervalSinceReferenceDate);
}
