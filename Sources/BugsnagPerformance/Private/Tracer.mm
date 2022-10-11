//
//  Tracer.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "Tracer.h"

#import "BatchSpanProcessor.h"
#import "Instrumentation/AppStartupInstrumentation.h"
#import "OtlpTraceExporter.h"
#import "Span.h"

using namespace bugsnag;

Tracer::Tracer() noexcept
: spanProcessor_(std::make_shared<BatchSpanProcessor>())
{}

Tracer::~Tracer() noexcept
{}

void
Tracer::start(NSURL *endpoint,
              bool autoInstrumentAppStarts) noexcept {
    auto serviceName = NSBundle.mainBundle.bundleIdentifier ?: NSProcessInfo.processInfo.processName;
    auto resourceAttributes = @{
        @"service.name": serviceName,
        @"telemetry.sdk.name": @"bugsnag.performance.cocoa",
        @"telemetry.sdk.version": @"0.0",
    };
    
    auto exporter = std::make_shared<OtlpTraceExporter>(endpoint, resourceAttributes);
    dynamic_cast<BatchSpanProcessor *>(spanProcessor_.get())->setSpanExporter(exporter);
    
    if (autoInstrumentAppStarts) {
        appStartupInstrumentation_ = std::make_unique<AppStartupInstrumentation>(*this);
        appStartupInstrumentation_->start();
    }
    
    NSLog(@"BugsnagPerformance started");
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
