//
//  Worker.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 14.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import "AsyncToSyncTask.h"
#import "../BSGPhasedStartup.h"

#import <memory>

using namespace bugsnag;

NS_ASSUME_NONNULL_BEGIN

/**
 * The worker performs a set series of tasks on a background thread.
 */
@interface Worker : NSObject<BSGPhasedStartup>

+ (instancetype)worker;

- (void)addInitialTask:(std::shared_ptr<AsyncToSyncTask>)task;
- (void)addRecurringTask:(std::shared_ptr<AsyncToSyncTask>)task;

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
