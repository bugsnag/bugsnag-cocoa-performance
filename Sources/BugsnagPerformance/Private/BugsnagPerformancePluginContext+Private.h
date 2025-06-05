//
//  BugsnagPerformancePluginContext+Private.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 03/06/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformancePluginContext.h>

typedef void (^ AddStartSpanCallbackBlock)(BugsnagPerformanceSpanStartCallback object, BugsnagPerformancePriority priority);

typedef void (^ AddEndSpanCallbackBlock)(BugsnagPerformanceSpanEndCallback object, BugsnagPerformancePriority priority);

@interface BugsnagPerformancePluginContext ()

@end
