//
//  BugsnagPerformanceSpan.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "../Private/BugsnagPerformanceSpan+Private.h"

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
    if (_span) {
        _span->end(CFAbsoluteTimeGetCurrent());
        _span.reset();
    }
}

- (void)endWithEndTime:(NSDate *)endTime {
    if (_span) {
        _span->end(endTime.timeIntervalSinceReferenceDate);
        _span.reset();
    }
}

@end
