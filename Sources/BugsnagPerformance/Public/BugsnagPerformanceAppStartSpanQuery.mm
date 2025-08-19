//
//  BugsnagPerformanceAppStartSpanQuery.mm
//  BugsnagPerformance
//
//  Created by Daria Bialobrzeska on 18/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "BugsnagPerformanceAppStartSpanQuery.h"
#import "BugsnagPerformanceAppStartSpanControl.h"

@implementation BugsnagPerformanceAppStartSpanQuery
+ (instancetype)query {
    return [self queryWithResultType:[BugsnagPerformanceAppStartSpanControl class]];
}

@end
