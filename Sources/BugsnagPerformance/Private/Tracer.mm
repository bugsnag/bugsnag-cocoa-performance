//
//  Tracer.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "Tracer.h"

#import "BatchSpanProcessor.h"
#import "OtlpTraceExporter.h"

using namespace bugsnag;

Tracer::Tracer() noexcept
: spanProcessor(std::make_shared<BatchSpanProcessor>())
{}

void
Tracer::start(NSURL *endpoint) noexcept {
    auto serviceName = NSBundle.mainBundle.bundleIdentifier ?: NSProcessInfo.processInfo.processName;
    auto resourceAttributes = @{
        @"service.name": serviceName,
        @"telemetry.sdk.name": @"bugsnag.performance.cocoa",
        @"telemetry.sdk.version": @"0.0",
    };
    
    auto exporter = std::make_shared<OtlpTraceExporter>(endpoint, resourceAttributes);
    dynamic_cast<BatchSpanProcessor *>(spanProcessor.get())->setSpanExporter(exporter);
    
    NSLog(@"BugsnagPerformance started");
}

SpanPtr
Tracer::startSpan(NSString *name, CFAbsoluteTime startTime) noexcept {
    return std::make_shared<Span>(name, startTime, spanProcessor);
}
