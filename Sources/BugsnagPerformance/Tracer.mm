//
//  Tracer.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "Tracer.h"

#import "OtlpTraceExporter.h"

using namespace bugsnag;

Tracer::Tracer(NSURL *endpoint) noexcept : endpoint(endpoint) {
    auto serviceName = NSBundle.mainBundle.bundleIdentifier ?: NSProcessInfo.processInfo.processName;
    resourceAttributes = @{
        @"service.name": serviceName,
        @"telemetry.sdk.name": @"bugsnag.performance.cocoa",
        @"telemetry.sdk.version": @"0.0",
    };
    
    NSLog(@"BugsnagPerformance started");
}

std::shared_ptr<Span>
Tracer::startSpan(NSString *name, CFAbsoluteTime startTime) noexcept {
    return std::make_shared<Span>(name, startTime, ^(const Span &span) {
        this->onEnd(span);
    });
}

void
Tracer::onEnd(const Span &span) noexcept {
    auto request = OtlpTraceExporter::encode(span, resourceAttributes);
    
    NSError *error = nil;
    auto data = [NSJSONSerialization dataWithJSONObject:request options:NSJSONWritingPrettyPrinted error:&error];
    if (!data) {
        NSCAssert(NO, @"%@", error);
        return;
    }
    
    auto urlRequest = [NSMutableURLRequest requestWithURL:endpoint];
    urlRequest.HTTPBody = data;
    urlRequest.HTTPMethod = @"POST";
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [[NSURLSession.sharedSession dataTaskWithRequest:urlRequest] resume];
}
