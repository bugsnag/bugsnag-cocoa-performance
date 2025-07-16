//
//  BatchTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 03.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Batch.h"

using namespace bugsnag;

@interface BatchTests : XCTestCase

@end

@implementation BatchTests

static BugsnagPerformanceSpan *newSpanData() {
    TraceId tid = {.value = 1};
    MetricsOptions metricsOptions;
    return [[BugsnagPerformanceSpan alloc] initWithName:@"test"
                                                traceId:tid
                                                 spanId:1
                                               parentId:0
                                              startTime:0
                                             firstClass:BSGTriStateUnset
                                    samplingProbability:1.0
                                    attributeCountLimit:128
                                         metricsOptions:metricsOptions
                                     assignedConditions:@[]
                                           onSpanEndSet:^(BugsnagPerformanceSpan * _Nonnull) {}
                                           onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}
                                          onSpanBlocked:^BugsnagPerformanceSpanCondition * _Nullable(BugsnagPerformanceSpan * _Nonnull, NSTimeInterval) { return nil; }];
}

- (void)testDrainAllow {
    Batch batch;
    BugsnagPerformanceConfiguration *config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"];
    config.internal.autoTriggerExportOnBatchSize = 1000;
    batch.configure(config);
    __block int callbackCalls = 0;

    batch.setBatchFullCallback(^{
        callbackCalls++;
    });
    
    // Drain not allowed until explicitly allowed
    batch.add(newSpanData());
    auto drained = batch.drain(false);
    XCTAssertEqual(drained.count, 0U);
    XCTAssertEqual(callbackCalls, 0);

    // Allow one drain
    batch.allowDrain();
    drained = batch.drain(false);
    XCTAssertEqual(drained.count, 1U);
    XCTAssertEqual(callbackCalls, 0);

    // Drain only allowed once per allow
    batch.add(newSpanData());
    drained = batch.drain(false);
    XCTAssertEqual(drained.count, 0U);
    XCTAssertEqual(callbackCalls, 0);

    // Allow another drain and also add another span for a total of 2
    batch.allowDrain();
    batch.add(newSpanData());
    drained = batch.drain(false);
    XCTAssertEqual(drained.count, 2U);
    XCTAssertEqual(callbackCalls, 0);
}

- (void)testBatchFull {
    __block std::shared_ptr<Batch> batch = std::make_shared<Batch>();
    BugsnagPerformanceConfiguration *config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"];
    config.internal.autoTriggerExportOnBatchSize = 1;
    batch->configure(config);
    __block int callbackCalls = 0;
    
    batch->setBatchFullCallback(^{
        callbackCalls++;
    });
    
    // Auto triggers at size 1
    batch->add(newSpanData());
    auto drained = batch->drain(false);
    XCTAssertEqual(drained.count, 1U);
    XCTAssertEqual(callbackCalls, 1);
    
    batch = std::make_shared<Batch>();
    batch->setBatchFullCallback(^{
        callbackCalls++;
    });
    callbackCalls = 0;
    config.internal.autoTriggerExportOnBatchSize = 2;
    batch->configure(config);

    // Doesn't trigger after 1 entry, and drain not explicitly allowed
    batch->add(newSpanData());
    drained = batch->drain(false);
    XCTAssertEqual(drained.count, 0U);
    XCTAssertEqual(callbackCalls, 0);
    
    // Does trigger after 2nd entry
    batch->add(newSpanData());
    drained = batch->drain(false);
    XCTAssertEqual(drained.count, 2U);
    XCTAssertEqual(callbackCalls, 1);
    
    // Doesn't trigger after 3rd entry (1st entry after draining)
    callbackCalls = 0;
    batch->add(newSpanData());
    drained = batch->drain(false);
    XCTAssertEqual(drained.count, 0U);
    XCTAssertEqual(callbackCalls, 0);
    
    // Does trigger after 4th entry (2nd entry after draining)
    batch->add(newSpanData());
    drained = batch->drain(false);
    XCTAssertEqual(drained.count, 2U);
    XCTAssertEqual(callbackCalls, 1);
    
}

- (void)testChaosMonkey {
    __block bool stopThread = false;
    __block std::shared_ptr<Batch> batch = std::make_shared<Batch>();
    BugsnagPerformanceConfiguration *config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"];
    config.internal.autoTriggerExportOnBatchSize = 2;
    batch->configure(config);

    [NSThread detachNewThreadWithBlock:^{
        while (!stopThread) {
            batch->drain(false);
        }
    }];

    for(int i = 0; i < 500000; i++) {
        batch->add(newSpanData());
    }
    
    stopThread = true;
    [NSThread sleepForTimeInterval:0.1];
}

@end
