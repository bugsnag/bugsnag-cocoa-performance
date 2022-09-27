//
//  Span.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <Foundation/Foundation.h>

#import "IdGenerator.h"
#import "SpanKind.h"

// https://opentelemetry.io/docs/reference/specification/trace/api/#span
class Span {
public:
    Span(NSString *name, CFAbsoluteTime startTime, void (^onEnd)(const Span &span)) noexcept;
    
    void end(CFAbsoluteTime time = CFAbsoluteTimeGetCurrent()) noexcept;
    
    TraceId traceId;
    SpanId spanId;
    NSString *name;
    SpanKind kind = SPAN_KIND_INTERNAL;
    NSDictionary *attributes = nil;
    CFAbsoluteTime startTime;
    CFAbsoluteTime endTime;
    
private:
    void (^onEnd)(const Span &span);
};
