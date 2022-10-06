//
//  OtlpTraceExporter.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 05/10/2022.
//

#import "OtlpTraceExporter.h"

#import "OtlpTraceEncoding.h"

using namespace bugsnag;

void
OtlpTraceExporter::exportSpans(std::vector<std::unique_ptr<SpanData>> spans) noexcept {
    auto request = OtlpTraceEncoding::encode(spans, resourceAttributes_);
    
    NSError *error = nil;
    auto data = [NSJSONSerialization dataWithJSONObject:request options:0 error:&error];
    if (!data) {
        NSCAssert(NO, @"%@", error);
        return;
    }
    
    auto urlRequest = [NSMutableURLRequest requestWithURL:endpoint_];
    urlRequest.HTTPBody = data;
    urlRequest.HTTPMethod = @"POST";
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [[NSURLSession.sharedSession dataTaskWithRequest:urlRequest] resume];
}
