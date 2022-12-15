//
//  WorkerTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 30.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "Worker.h"

@interface WorkerTests : XCTestCase

@end

@interface WorkerTester: NSObject

+ (instancetype) workerWithInitialTaskCount:(int)initialTaskCount
                      recurringTaskCount:(int)recurringTaskCount
                       recurringRuns:(int)recurringRuns
                        workInterval:(NSTimeInterval)workInterval
                                  sleepTime:(NSTimeInterval)sleepTime;

- (instancetype) initWithInitialTaskCount:(int)initialTaskCount
                       recurringTaskCount:(int)recurringTaskCount
                        recurringRuns:(int)recurringRuns
                         workInterval:(NSTimeInterval)workInterval
                            sleepTime:(NSTimeInterval)sleepTime;

@property(nonatomic,readonly) int initialTaskCount;
@property(nonatomic,readonly) int recurringTaskCount;
@property(nonatomic,readonly) NSTimeInterval workInterval;
@property(nonatomic,readonly) NSTimeInterval sleepTime;
@property(nonatomic,readwrite) int recurringRuns;
@property(nonatomic,readwrite) int initialTaskCounter;
@property(nonatomic,readwrite) int recurringTaskCounter;

- (void) run;

@end


@implementation WorkerTests

- (void)test0Initial0Recurring1Run {
    auto workerTester = [WorkerTester workerWithInitialTaskCount:0
                                              recurringTaskCount:0
                                                   recurringRuns:1
                                                    workInterval:30
                                                       sleepTime:0.2];
    [workerTester run];

    XCTAssertEqual(workerTester.initialTaskCounter, 0);
    XCTAssertEqual(workerTester.recurringTaskCounter, 0);
}

- (void)test1Initial0Recurring1Run {
    auto workerTester = [WorkerTester workerWithInitialTaskCount:1
                                              recurringTaskCount:0
                                                   recurringRuns:1
                                                    workInterval:30
                                                       sleepTime:0.2];
    [workerTester run];

    XCTAssertEqual(workerTester.initialTaskCounter, 1);
    XCTAssertEqual(workerTester.recurringTaskCounter, 0);
}

- (void)test0Initial1Recurring1Run {
    auto workerTester = [WorkerTester workerWithInitialTaskCount:0
                                              recurringTaskCount:1
                                                   recurringRuns:1
                                                    workInterval:30
                                                       sleepTime:0.2];
    [workerTester run];

    XCTAssertEqual(workerTester.initialTaskCounter, 0);
    XCTAssertEqual(workerTester.recurringTaskCounter, 1);
}

- (void)test1Initial1Recurring1Run {
    auto workerTester = [WorkerTester workerWithInitialTaskCount:1
                                              recurringTaskCount:1
                                                   recurringRuns:1
                                                    workInterval:30
                                                       sleepTime:0.2];
    [workerTester run];

    XCTAssertEqual(workerTester.initialTaskCounter, 1);
    XCTAssertEqual(workerTester.recurringTaskCounter, 1);
}

- (void)test1Initial1Recurring2Runs {
    auto workerTester = [WorkerTester workerWithInitialTaskCount:1
                                              recurringTaskCount:1
                                                   recurringRuns:2
                                                    workInterval:30
                                                       sleepTime:0.2];
    [workerTester run];

    XCTAssertEqual(workerTester.initialTaskCounter, 1);
    XCTAssertEqual(workerTester.recurringTaskCounter, 2);
}

- (void)test2Initial2Recurring1Run {
    auto workerTester = [WorkerTester workerWithInitialTaskCount:2
                                              recurringTaskCount:2
                                                   recurringRuns:1
                                                    workInterval:30
                                                       sleepTime:0.2];
    [workerTester run];

    XCTAssertEqual(workerTester.initialTaskCounter, 2);
    XCTAssertEqual(workerTester.recurringTaskCounter, 2);
}

- (void)test2Initial2Recurring2Runs {
    auto workerTester = [WorkerTester workerWithInitialTaskCount:2
                                              recurringTaskCount:2
                                                   recurringRuns:2
                                                    workInterval:30
                                                       sleepTime:0.2];
    [workerTester run];

    XCTAssertEqual(workerTester.initialTaskCounter, 2);
    XCTAssertEqual(workerTester.recurringTaskCounter, 4);
}

- (void)test1Initial1Recurring1RunSmallInterval {
    auto workerTester = [WorkerTester workerWithInitialTaskCount:1
                                              recurringTaskCount:1
                                                   recurringRuns:1
                                                    workInterval:0.1
                                                       sleepTime:0.4];
    [workerTester run];

    XCTAssertEqual(workerTester.initialTaskCounter, 1);
    XCTAssertTrue(workerTester.recurringTaskCounter > 1);
}

@end


@implementation WorkerTester

+ (instancetype) workerWithInitialTaskCount:(int)initialTaskCount
                      recurringTaskCount:(int)recurringTaskCount
                       recurringRuns:(int)recurringRuns
                        workInterval:(NSTimeInterval)workInterval
                               sleepTime:(NSTimeInterval)sleepTime {
    return [[self alloc] initWithInitialTaskCount:initialTaskCount
                               recurringTaskCount:recurringTaskCount
                                    recurringRuns:recurringRuns
                                     workInterval:workInterval
                                        sleepTime:sleepTime];
}

- (instancetype) initWithInitialTaskCount:(int)initialTaskCount
                       recurringTaskCount:(int)recurringTaskCount
                        recurringRuns:(int)recurringRuns
                         workInterval:(NSTimeInterval)workInterval
                            sleepTime:(NSTimeInterval)sleepTime {
    if ((self = [super init])) {
        _initialTaskCount = initialTaskCount;
        _recurringTaskCount = recurringTaskCount;
        _recurringRuns = recurringRuns;
        _workInterval = workInterval;
        _sleepTime = sleepTime;
    }
    return self;
}

- (Task) newInitialTask {
    return ^bool(){
        self.initialTaskCounter++;
        return false;
    };
}

- (Task) newRecurringTask {
    return ^bool(){
        self.recurringTaskCounter++;
        self.recurringRuns--;
        return self.recurringRuns > 0;
    };
}

- (void) run {
    auto initialTasks = [NSMutableArray array];
    for (int i = 0; i < self.initialTaskCount; i++) {
        [initialTasks addObject:[self newInitialTask]];
    }

    auto recurringTasks = [NSMutableArray array];
    for (int i = 0; i < self.recurringTaskCount; i++) {
        [recurringTasks addObject:[self newRecurringTask]];
    }

    auto worker = [[Worker alloc] initWithInitialTasks:initialTasks
                                        recurringTasks:recurringTasks
                                          workInterval:self.workInterval];

    [worker start];
    [NSThread sleepForTimeInterval:self.sleepTime];
    [worker destroy];
}

@end
