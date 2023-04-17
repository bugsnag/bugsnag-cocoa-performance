//
//  BugsnagPerformanceSpan.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "../Private/BugsnagPerformanceSpan+Private.h"
#import "../Private/Utils.h"

using namespace bugsnag;

@implementation BugsnagPerformanceSpan {
    std::unique_ptr<Span> _span;
}

- (instancetype)initWithSpan:(std::unique_ptr<Span>)span {
    if ((self = [super init])) {
        _span = std::move(span);
    }
    return self;
}

// We want direct ivar access to avoid accessors copying unique_ptrs
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

- (void)end {
    NSLog(@"### BugsnagPerformanceSpan::end");
    _span->end(CFAbsoluteTimeGetCurrent());
}

- (void)endWithEndTime:(NSDate *)endTime {
    NSLog(@"### BugsnagPerformanceSpan::endWithEndTime");
    _span->end(dateToAbsoluteTime(endTime));
}

- (void)endWithAbsoluteTime:(CFAbsoluteTime)endTime {
    NSLog(@"### BugsnagPerformanceSpan::endWithAbsoluteTime"); 
    _span->end(endTime);
}

- (TraceId)traceId {
    return _span->traceId();
}

- (SpanId)spanId {
    return _span->spanId();
}

- (BOOL)isValid {
    return !_span->isEnded();
}

- (void)addAttributes:(NSDictionary *)attributes {
    _span->addAttributes(attributes);
}

- (BOOL)hasAttribute:(NSString *)attributeName withValue:(id)value {
    return _span->hasAttribute(attributeName, value);
}

@end
