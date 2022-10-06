//
//  BugsnagPerformanceSpan.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "../Private/BugsnagPerformanceSpan+Private.h"

using namespace bugsnag;

@implementation BugsnagPerformanceSpan {
    SpanPtr _span;
}

- (instancetype)initWithSpan:(SpanPtr)span {
    if ((self = [super init])) {
        _span = span;
    }
    return self;
}

- (void)end {
    if (_span) {
        Span::end(_span, CFAbsoluteTimeGetCurrent());
        _span.reset();
    }
}

- (void)endWithEndTime:(NSDate *)endTime {
    if (_span) {
        Span::end(_span, endTime.timeIntervalSinceReferenceDate);
        _span.reset();
    }
}

@end
