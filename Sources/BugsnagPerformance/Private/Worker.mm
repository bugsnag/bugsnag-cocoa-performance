//
//  Worker.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 14.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "Worker.h"

@interface Worker ()

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
    NSLog(@"### worker::run");
    [self performInitialWork];

    for (;;) {
        NSLog(@"### worker::run: loop");
        @autoreleasepool {
            if (self.shouldEnd) {
                break;
            }

            while ([self performRecurringWork]) {
                // Keep working until no work gets done
            }

            // Once there's no work getting done, go to sleep.
            [self.condition lock];
            [self.condition wait];
            [self.condition unlock];
        }
    }
    NSLog(@"### worker::run: end");
}

- (void) start {
    self.shouldEnd = false;
    [self.thread start];
}

- (void) wake {
    [self.condition lock];
    [self.condition signal];
    [self.condition unlock];
}

- (void) destroy {
    self.shouldEnd = true;
    [self wake];
}

@end
