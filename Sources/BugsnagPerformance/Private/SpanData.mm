//
//  SpanData.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import "SpanData.h"

using namespace bugsnag;

SpanData::SpanData(NSString *name, CFAbsoluteTime startTime) noexcept
: name([name copy])
, attributes([NSMutableDictionary dictionary])
, startTime(startTime)
{
    IdGenerator::generateTraceIdBytes(traceId);
    IdGenerator::generateSpanIdBytes(spanId);
}

void
SpanData::addAttributes(NSDictionary *attributes) noexcept {
    [this->attributes addEntriesFromDictionary:attributes];
}
