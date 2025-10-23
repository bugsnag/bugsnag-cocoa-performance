//
//  Worker.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 14.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "Worker.h"
#import "../Configuration/BugsnagPerformanceConfiguration+Private.h"
#import <vector>

@interface Worker ()

@property(readwrite,atomic) NSTimeInterval initialRecurringWorkDelay;
@property(readwrite,atomic) BOOL isStarted;
@property(readwrite,atomic) BOOL shouldEnd;
@property(readonly,nonatomic) NSCondition *condition;
@property(readonly,nonatomic) NSThread *thread;
@property(nonatomic) std::vector<std::shared_ptr<AsyncToSyncTask>> initialTasks;
@property(nonatomic) std::vector<std::shared_ptr<AsyncToSyncTask>> recurringTasks;

@end

@implementation Worker

+ (instancetype)worker {
    return [self new];
}

- (instancetype)init {
    if ((self = [super init])) {
        _condition = [[NSCondition alloc] init];
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
        _initialTasks = std::vector<std::shared_ptr<AsyncToSyncTask>>();
        _recurringTasks = std::vector<std::shared_ptr<AsyncToSyncTask>>();
        _isStarted = false;
        _shouldEnd = false;
    }
    return self;
}

- (void)addInitialTask:(std::shared_ptr<AsyncToSyncTask>)task {
    @synchronized (self) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
        _initialTasks.push_back(task);
#pragma clang diagnostic pop
    }
}

- (void)addRecurringTask:(std::shared_ptr<AsyncToSyncTask>)task {
    @synchronized (self) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
        _recurringTasks.push_back(task);
#pragma clang diagnostic pop
    }
}

- (void)performInitialWork {
    @autoreleasepool {
        @synchronized (self) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
            for (const auto &task : _initialTasks) {
                task->executeSync();
            }
            _initialTasks.clear();
#pragma clang diagnostic pop
        }
    }
}

- (bool) performRecurringWork {
    bool performedWork = false;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    for (const auto &task : _recurringTasks) {
        @autoreleasepool {
            performedWork |= task->executeSync();
        }
    }
#pragma clang diagnostic pop
    return performedWork;
}

- (void) run {
    @autoreleasepool {
        // Start off asleep
        [self sleep];
        if (self.shouldEnd) {
            return;
        }

        [self performInitialWork];

        if (self.initialRecurringWorkDelay > 0) {
            [NSThread sleepForTimeInterval:self.initialRecurringWorkDelay];
        }

        for (;;) {
            @autoreleasepool {
                if (self.shouldEnd) {
                    break;
                }

                while ([self performRecurringWork]) {
                    // Keep working until no work gets done
                }

                // Once there's no work getting done, go to sleep.
                [self sleep];
            }
        }
    }
}

- (void)earlyConfigure:(BSGEarlyConfiguration *)config {

}

- (void)earlySetup {

}

- (void)configure:(BugsnagPerformanceConfiguration *)config {
    self.initialRecurringWorkDelay = config.internal.initialRecurringWorkDelay;
}

- (void)preStartSetup {

}

- (void) start {
    self.isStarted = true;
    self.shouldEnd = false;
    [self.thread start];
}

- (void) sleep {
    [self.condition lock];
    [self.condition wait];
    [self.condition unlock];
}

- (void) wake {
    if (self.isStarted) {
        [self.condition lock];
        [self.condition signal];
        [self.condition unlock];
    }
}

- (void) destroy {
    self.shouldEnd = true;
    [self wake];
}

@end
