//
//  Worker.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 14.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef bool (^Task)();

/**
 * The worker performs a set series of tasks on a background thread.
 */
@interface Worker : NSObject

- (instancetype) initWithInitialTasks:(NSArray<Task> *)initialTasks recurringTasks:(NSArray<Task> *)recurringTasks workInterval:(NSTimeInterval)workInterval;

/**
 * Start the worker thread, running the initial tasks and one run of the recurring tasks right away.
 */
- (void) start;

/**
 * Wake the worker to run through the recurring tasks until none of them do any work.
 * Once there's no work, the worker goes back to sleep.
 */
- (void) wake;

/**
 * Destroy this worker. Used in unit tests.
 */
- (void) destroy;

@end

NS_ASSUME_NONNULL_END
