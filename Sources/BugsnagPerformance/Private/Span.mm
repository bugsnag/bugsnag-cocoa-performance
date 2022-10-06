//
//  Span.m
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "Span.h"

#import "SpanProcessor.h"

using namespace bugsnag;

Span::Span(NSString *name, CFAbsoluteTime startTime, std::shared_ptr<SpanProcessor> spanProcessor) noexcept
: name([name copy]), startTime(startTime), spanProcessor(spanProcessor) {
    IdGenerator::generateSpanIdBytes(spanId);
    IdGenerator::generateTraceIdBytes(traceId);
}

void
Span::end(SpanPtr span, CFAbsoluteTime time) noexcept {
    if (span->endTime) {
        return;
    }
    span->endTime = time;
    span->spanProcessor->onEnd(span);
}
