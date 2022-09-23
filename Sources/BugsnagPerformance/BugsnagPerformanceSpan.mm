//
//  BugsnagPerformanceSpan.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "BugsnagPerformanceSpan+Private.h"

@implementation BugsnagPerformanceSpan {
    Span *_span;
}

- (instancetype)initWithSpan:(Span *)span {
    if ((self = [super init])) {
        _span = span;
    }
    return self;
}

- (void)dealloc {
    delete _span;
}

- (void)end {
    _span->end();
}

@end
