//
//  SpanData.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import "SpanData.h"

using namespace bugsnag;

SpanData::SpanData(NSString *name, TraceId traceId, SpanId spanId, SpanId parentId, CFAbsoluteTime startTime) noexcept
: traceId(traceId)
, spanId(spanId)
, parentId(parentId)
, name([name copy])
, attributes([NSMutableDictionary dictionary])
, samplingProbability(1.0)
, startTime(startTime)
{
}

void
SpanData::addAttributes(NSDictionary *dictionary) noexcept {
    [this->attributes addEntriesFromDictionary:dictionary];
}

void
SpanData::updateSamplingProbability(double value) noexcept {
    if (samplingProbability > value) {
        samplingProbability = value;
        attributes[@"bugsnag.sampling.p"] = @(value);
    }
}
