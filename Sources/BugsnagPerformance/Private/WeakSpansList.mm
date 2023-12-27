//
//  WeakSpansList.c
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 12.12.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "WeakSpansList.h"

@implementation BSGWeakSpanPointer

- (instancetype) initWithSpan:(BugsnagPerformanceSpan *)span {
    if ((self = [super init])) {
        _span = span;
    }
    return self;
}

+ (instancetype) pointerWithSpan:(BugsnagPerformanceSpan *)span {
    return [[self alloc] initWithSpan:span];
}

@end
