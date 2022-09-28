//
//  BugsnagPerformanceSpan.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "BugsnagPerformanceSpan+Private.h"

using namespace bugsnag;

@implementation BugsnagPerformanceSpan {
    std::shared_ptr<Span> _span;
}

- (instancetype)initWithSpan:(std::shared_ptr<Span>)span {
    if ((self = [super init])) {
        _span = span;
    }
    return self;
}

- (void)end {
    if (_span) {
        _span->end();
    }
}

- (void)endWithTime:(NSDate *)time {
    if (_span) {
        _span->end(time.timeIntervalSinceReferenceDate);
    }
}

@end
