//
//  Span.m
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "Span.h"

using namespace bugsnag;

Span::Span(NSString *name, CFAbsoluteTime startTime, void (^onEnd)(const Span &span)) noexcept
: name([name copy]), startTime(startTime), onEnd(onEnd) {
    IdGenerator::generateSpanIdBytes(spanId);
    IdGenerator::generateTraceIdBytes(traceId);
}

void
Span::end(CFAbsoluteTime time) noexcept {
    endTime = time;
    onEnd(*this);
}
