//
//  Span.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <Foundation/Foundation.h>

#import "IdGenerator.h"
#import "SpanKind.h"

#import <memory>
#import <vector>

namespace bugsnag {
typedef std::shared_ptr<class Span> SpanPtr;

// https://opentelemetry.io/docs/reference/specification/trace/api/#span
class Span {
public:
    Span(NSString *name, CFAbsoluteTime startTime, std::shared_ptr<class SpanProcessor> spanProcessor) noexcept;
    
    Span(const Span&) = delete;
    
    // Declared as a static function to allow shared_ptr to be passed and avoid copying objects.
    static void end(SpanPtr span, CFAbsoluteTime time) noexcept;
    
    TraceId traceId;
    SpanId spanId;
    NSString *name;
    SpanKind kind = SPAN_KIND_INTERNAL;
    NSDictionary *attributes = nil;
    CFAbsoluteTime startTime;
    CFAbsoluteTime endTime = 0;
    
private:
    std::shared_ptr<class SpanProcessor> spanProcessor;
};
}
