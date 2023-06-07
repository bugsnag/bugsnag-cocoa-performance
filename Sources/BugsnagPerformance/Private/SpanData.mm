//
//  SpanData.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import "SpanData.h"

using namespace bugsnag;

SpanData::SpanData(NSString *name,
                   TraceId traceId,
                   SpanId spanId,
                   SpanId parentId,
                   CFAbsoluteTime startTime,
                   BSGFirstClass firstClass) noexcept
: traceId(traceId)
, spanId(spanId)
, parentId(parentId)
, name([name copy])
, attributes([NSMutableDictionary dictionary])
, samplingProbability(1.0)
, startTime(startTime)
, firstClass(firstClass)
{
    if (firstClass != BSGFirstClassUnset) {
        attributes[@"bugsnag.span.first_class"] = @(firstClass == BSGFirstClassYes);
    }
}

void
SpanData::addAttributes(NSDictionary *dictionary) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    [this->attributes addEntriesFromDictionary:dictionary];
}

bool
SpanData::hasAttribute(NSString *attributeName, id value) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    for (id key in attributes) {
        if ([key isEqualToString:attributeName]) {
            return [attributes[key] isEqual:value];
        }
    }
    return false;
}

void
SpanData::updateSamplingProbability(double value) noexcept {
    if (samplingProbability > value) {
        samplingProbability = value;
        attributes[@"bugsnag.sampling.p"] = @(value);
    }
}
