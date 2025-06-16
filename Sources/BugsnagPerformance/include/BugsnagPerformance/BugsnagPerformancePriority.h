//
//  BugsnagPerformancePriority.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/05/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Calling priority for callbacks and providers.
 */
typedef NSInteger BugsnagPerformancePriority;

/**
 *  High priority, for callbacks and providers that need to be called early
 */
extern const BugsnagPerformancePriority BugsnagPerformancePriorityHigh;

/**
 *  Default priority
 */
extern const BugsnagPerformancePriority BugsnagPerformancePriorityMedium;

/**
 *  Low priority, for callbacks and providers that need to be called late
 */
extern const BugsnagPerformancePriority BugsnagPerformancePriorityLow;
