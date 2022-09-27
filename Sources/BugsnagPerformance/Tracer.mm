//
//  Tracer.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "Tracer.h"

#import "TraceServiceRequest.h"

void
Tracer::onEnd(const Span &span) {
    auto request = TraceServiceRequest::encode(span);
    
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
