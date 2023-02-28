//
//  SpanData.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

#import "IdGenerator.h"
#import "SpanKind.h"

namespace bugsnag {
/**
 * SpanData is a representation of all data collected by a span.
 */
class SpanData {
public:
    SpanData(NSString *name,
             TraceId traceId,
             SpanId spanId,
             SpanId parentId,
             CFAbsoluteTime startTime,
             bool isFirstClass) noexcept;
    
    SpanData(const SpanData&) = delete;
    
    void addAttributes(NSDictionary *attributes) noexcept;
    
    void updateSamplingProbability(double value) noexcept;
    
    TraceId traceId;
    SpanId spanId;
    SpanId parentId;
    NSString *name;
    SpanKind kind = SPAN_KIND_INTERNAL;
    NSMutableDictionary *attributes;
    double samplingProbability;
    CFAbsoluteTime startTime;
    CFAbsoluteTime endTime = 0;
};
}
