//
//  Worker.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 14.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "Worker.h"
#import "BugsnagPerformanceConfiguration+Private.h"

@interface Worker ()

@property(readwrite,atomic) NSTimeInterval initialRecurringWorkDelay;
@property(readwrite,atomic) BOOL isStarted;
@property(readwrite,atomic) BOOL shouldEnd;
@property(readonly,nonatomic) NSCondition *condition;
@property(readonly,nonatomic) NSThread *thread;
@property(readwrite,nonatomic) NSArray<Task> *initialTasks;
@property(readonly,nonatomic) NSArray<Task> *recurringTasks;

@end

@implementation Worker

- (instancetype) initWithInitialTasks:(NSArray<Task> *)initialTasks
                       recurringTasks:(NSArray<Task> *)recurringTasks {
    if ((self = [super init])) {
        _condition = [[NSCondition alloc] init];
        _thread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
        _initialTasks = initialTasks;
        _recurringTasks = recurringTasks;
        _isStarted = false;
        _shouldEnd = false;
    }
    return self;
}

- (void) performInitialWork {
    @autoreleasepool {
        for (Task task in self.initialTasks) {
            task();
        }
        self.initialTasks = nil;
    }
}

- (bool) performRecurringWork {
    bool performedWork = false;
    for (Task task in self.recurringTasks) {
        @autoreleasepool {
            performedWork |= task();
        }
    }
    return performedWork;
}

- (void) run {
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

- (void)earlyConfigure:(BSGEarlyConfiguration *)config {

}

- (void)earlySetup {

}

- (void)configure:(BugsnagPerformanceConfiguration *)config {
    self.initialRecurringWorkDelay = config.internal.initialRecurringWorkDelay;
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
