//
//  SpanData.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import <Foundation/Foundation.h>

#import "IdGenerator.h"
#import "SpanKind.h"

namespace bugsnag {
/**
 * SpanData is a representation of all data collected by a span.
 */
class SpanData {
public:
    SpanData(NSString *name, CFAbsoluteTime startTime) noexcept;
    
    SpanData(const SpanData&) = delete;
    
    TraceId traceId;
    SpanId spanId;
    NSString *name;
    SpanKind kind = SPAN_KIND_INTERNAL;
    NSDictionary *attributes = nil;
    CFAbsoluteTime startTime;
    CFAbsoluteTime endTime = 0;
};
}
