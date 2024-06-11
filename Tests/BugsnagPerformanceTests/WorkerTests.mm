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
                      recurringTaskCount:(int)recurringTaskCount;

- (instancetype) initWithInitialTaskCount:(int)initialTaskCount
                       recurringTaskCount:(int)recurringTaskCount;

@property(nonatomic,readwrite) int initialTaskCounter;
@property(nonatomic,readwrite) int recurringTaskCounter;
@property(nonatomic,readwrite) int remainingRecurringRuns;

@property(nonatomic,readonly) Worker *worker;

@end


@implementation WorkerTests

- (void)testNoTasks {
    auto workerTester = [WorkerTester workerWithInitialTaskCount:0
                                              recurringTaskCount:0];

    auto worker = workerTester.worker;

    XCTAssertEqual(workerTester.initialTaskCounter, 0);
    XCTAssertEqual(workerTester.recurringTaskCounter, 0);

    [worker start];

    XCTAssertEqual(workerTester.initialTaskCounter, 0);
    XCTAssertEqual(workerTester.recurringTaskCounter, 0);

    [worker wake];

    XCTAssertEqual(workerTester.initialTaskCounter, 0);
    XCTAssertEqual(workerTester.recurringTaskCounter, 0);

    [worker wake];

    XCTAssertEqual(workerTester.initialTaskCounter, 0);
    XCTAssertEqual(workerTester.recurringTaskCounter, 0);
}

- (void)test1InitialTask {
    auto workerTester = [WorkerTester workerWithInitialTaskCount:1
                                              recurringTaskCount:0];
    
    auto worker = workerTester.worker;
    
    XCTAssertEqual(workerTester.initialTaskCounter, 0);
    XCTAssertEqual(workerTester.recurringTaskCounter, 0);
    
    [worker start];
    [NSThread sleepForTimeInterval:0.1];

    XCTAssertEqual(workerTester.initialTaskCounter, 0);
    XCTAssertEqual(workerTester.recurringTaskCounter, 0);

    [worker wake];
    [NSThread sleepForTimeInterval:0.1];
    
    XCTAssertEqual(workerTester.initialTaskCounter, 1);
    XCTAssertEqual(workerTester.recurringTaskCounter, 0);
    
    [worker wake];
    [NSThread sleepForTimeInterval:0.1];

    XCTAssertEqual(workerTester.initialTaskCounter, 1);
    XCTAssertEqual(workerTester.recurringTaskCounter, 0);
}

- (void)test1RecurringTask {
    auto workerTester = [WorkerTester workerWithInitialTaskCount:0
                                              recurringTaskCount:1];
    
    auto worker = workerTester.worker;
    
    XCTAssertEqual(workerTester.initialTaskCounter, 0);
    XCTAssertEqual(workerTester.recurringTaskCounter, 0);
    
    [worker start];
    [NSThread sleepForTimeInterval:0.1];

    XCTAssertEqual(workerTester.initialTaskCounter, 0);
    XCTAssertEqual(workerTester.recurringTaskCounter, 0);

    [worker wake];
    [NSThread sleepForTimeInterval:0.1];
    
    XCTAssertEqual(workerTester.initialTaskCounter, 0);
    XCTAssertEqual(workerTester.recurringTaskCounter, 1);
    
    [worker wake];
    [NSThread sleepForTimeInterval:0.1];

    XCTAssertEqual(workerTester.initialTaskCounter, 0);
    XCTAssertEqual(workerTester.recurringTaskCounter, 2);
}

- (void)test1Initial1RecurringTask {
    auto workerTester = [WorkerTester workerWithInitialTaskCount:1
                                              recurringTaskCount:1];
    
    auto worker = workerTester.worker;
    
    XCTAssertEqual(workerTester.initialTaskCounter, 0);
    XCTAssertEqual(workerTester.recurringTaskCounter, 0);
    
    [worker start];
    [NSThread sleepForTimeInterval:0.1];

    XCTAssertEqual(workerTester.initialTaskCounter, 0);
    XCTAssertEqual(workerTester.recurringTaskCounter, 0);

    [worker wake];
    [NSThread sleepForTimeInterval:0.1];
    
    XCTAssertEqual(workerTester.initialTaskCounter, 1);
    XCTAssertEqual(workerTester.recurringTaskCounter, 1);
    
    [worker wake];
    [NSThread sleepForTimeInterval:0.1];

    XCTAssertEqual(workerTester.initialTaskCounter, 1);
    XCTAssertEqual(workerTester.recurringTaskCounter, 2);
}

- (void)test2Initial2RecurringTask {
    auto workerTester = [WorkerTester workerWithInitialTaskCount:2
                                              recurringTaskCount:2];
    
    auto worker = workerTester.worker;
    
    XCTAssertEqual(workerTester.initialTaskCounter, 0);
    XCTAssertEqual(workerTester.recurringTaskCounter, 0);
    
    [worker start];
    [NSThread sleepForTimeInterval:0.1];

    XCTAssertEqual(workerTester.initialTaskCounter, 0);
    XCTAssertEqual(workerTester.recurringTaskCounter, 0);

    [worker wake];
    [NSThread sleepForTimeInterval:0.1];
    
    XCTAssertEqual(workerTester.initialTaskCounter, 2);
    XCTAssertEqual(workerTester.recurringTaskCounter, 2);
    
    [worker wake];
    [NSThread sleepForTimeInterval:0.1];

    XCTAssertEqual(workerTester.initialTaskCounter, 2);
    XCTAssertEqual(workerTester.recurringTaskCounter, 4);
    
    [worker wake];
    [NSThread sleepForTimeInterval:0.1];

    XCTAssertEqual(workerTester.initialTaskCounter, 2);
    XCTAssertEqual(workerTester.recurringTaskCounter, 6);
}

@end


@implementation WorkerTester

+ (instancetype) workerWithInitialTaskCount:(int)initialTaskCount
                      recurringTaskCount:(int)recurringTaskCount {
    return [[self alloc] initWithInitialTaskCount:initialTaskCount
                               recurringTaskCount:recurringTaskCount];
}

- (instancetype) initWithInitialTaskCount:(int)initialTaskCount
                       recurringTaskCount:(int)recurringTaskCount {
    if ((self = [super init])) {
        _remainingRecurringRuns = 1;
        auto initialTasks = [NSMutableArray array];
        for (int i = 0; i < initialTaskCount; i++) {
            [initialTasks addObject:[self newInitialTask]];
        }

        auto recurringTasks = [NSMutableArray array];
        for (int i = 0; i < recurringTaskCount; i++) {
            [recurringTasks addObject:[self newRecurringTask]];
        }

        _worker = [[Worker alloc] initWithInitialTasks:initialTasks
                                        recurringTasks:recurringTasks];
    }
    return self;
}


- (Task) newInitialTask {
    __block auto blockSelf = self;
    return ^bool(){
        blockSelf.initialTaskCounter++;
        return false;
    };
}

- (Task) newRecurringTask {
    __block auto blockSelf = self;
    return ^bool(){
        blockSelf.recurringTaskCounter++;
        blockSelf.remainingRecurringRuns--;
        return blockSelf.remainingRecurringRuns > 0;
    };
}

@end
