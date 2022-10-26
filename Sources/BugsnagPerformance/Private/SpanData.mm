//
//  SpanData.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import "SpanData.h"

using namespace bugsnag;

SpanData::SpanData(NSString *name, CFAbsoluteTime startTime) noexcept
: traceId(IdGenerator::generateTraceIdBytes())
, spanId(IdGenerator::generateSpanIdBytes())
, name([name copy])
, attributes([NSMutableDictionary dictionary])
, startTime(startTime)
{
}

void
SpanData::addAttributes(NSDictionary *dictionary) noexcept {
    [this->attributes addEntriesFromDictionary:dictionary];
}
