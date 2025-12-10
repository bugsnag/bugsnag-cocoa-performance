//
//  ViewLoadLoadingIndicatorState.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 26/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadLoadingIndicatorState.h"

@implementation ViewLoadLoadingIndicatorState

- (instancetype)init
{
    self = [super init];
    if (self) {
        _conditions = [NSMutableArray array];
    }
    return self;
}

@end
