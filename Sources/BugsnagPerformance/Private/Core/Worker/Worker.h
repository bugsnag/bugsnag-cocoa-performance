//
//  Worker.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 14.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import "../PhasedStartup.h"

NS_ASSUME_NONNULL_BEGIN

typedef bool (^Task)();

/**
 * The worker performs a set series of tasks on a background thread.
 */
@interface Worker : NSObject<BSGPhasedStartup>

- (instancetype) initWithInitialTasks:(NSArray<Task> *)initialTasks recurringTasks:(NSArray<Task> *)recurringTasks;

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
