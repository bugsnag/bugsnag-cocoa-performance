//
//  BatchTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 03.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Batch.h"
#import "SpanData.h"
#import "BSGInternalConfig.h"

using namespace bugsnag;

@interface BatchTests : XCTestCase

@property(nonatomic,readwrite) uint64_t batchSize;

@end

@implementation BatchTests

- (void)setUp {
    self.batchSize = bsgp_autoTriggerExportOnBatchSize;
}

- (void)tearDown {
    bsgp_autoTriggerExportOnBatchSize = self.batchSize;
}

- (void)testDrainAllow {
    bsgp_autoTriggerExportOnBatchSize = 1000;
    
    Batch batch;
    __block int callbackCalls = 0;

    batch.setBatchFullCallback(^{
        callbackCalls++;
    });
    
    // Drain not allowed until explicitly allowed
    batch.add(std::make_unique<SpanData>(@"", 0));
    auto drained = batch.drain();
    XCTAssertEqual(drained->size(), 0);
    XCTAssertEqual(callbackCalls, 0);

    // Allow one drain
    batch.allowDrain();
    drained = batch.drain();
    XCTAssertEqual(drained->size(), 1);
    XCTAssertEqual(callbackCalls, 0);

    // Drain only allowed once per allow
    batch.add(std::make_unique<SpanData>(@"", 0));
    drained = batch.drain();
    XCTAssertEqual(drained->size(), 0);
    XCTAssertEqual(callbackCalls, 0);

    // Allow another drain and also add another span for a total of 2
    batch.allowDrain();
    batch.add(std::make_unique<SpanData>(@"", 0));
    drained = batch.drain();
    XCTAssertEqual(drained->size(), 2);
    XCTAssertEqual(callbackCalls, 0);
}

- (void)testBatchFull {
    bsgp_autoTriggerExportOnBatchSize = 1;
    
    Batch batch;
    __block int callbackCalls = 0;
    
    batch.setBatchFullCallback(^{
        callbackCalls++;
    });
    
    // Auto triggers at size 1
    batch.add(std::make_unique<SpanData>(@"", 0));
    auto drained = batch.drain();
    XCTAssertEqual(drained->size(), 1);
    XCTAssertEqual(callbackCalls, 1);
    
    bsgp_autoTriggerExportOnBatchSize = 2;
    callbackCalls = 0;
    
    // Doesn't trigger after 1 entry, and drain not explicitly allowed
    batch.add(std::make_unique<SpanData>(@"", 0));
    drained = batch.drain();
    XCTAssertEqual(drained->size(), 0);
    XCTAssertEqual(callbackCalls, 0);
    
    // Does trigger after 2nd entry
    batch.add(std::make_unique<SpanData>(@"", 0));
    drained = batch.drain();
    XCTAssertEqual(drained->size(), 2);
    XCTAssertEqual(callbackCalls, 1);
    
    // Doesn't trigger after 3rd entry (1st entry after draining)
    callbackCalls = 0;
    batch.add(std::make_unique<SpanData>(@"", 0));
    drained = batch.drain();
    XCTAssertEqual(drained->size(), 0);
    XCTAssertEqual(callbackCalls, 0);
    
    // Does trigger after 4th entry (2nd entry after draining)
    batch.add(std::make_unique<SpanData>(@"", 0));
    drained = batch.drain();
    XCTAssertEqual(drained->size(), 2);
    XCTAssertEqual(callbackCalls, 1);
    
}

- (void)testChaosMonkey {
    bsgp_autoTriggerExportOnBatchSize = 2;
    __block bool stopThread = false;
    __block std::shared_ptr<Batch> batch = std::make_shared<Batch>();

    [NSThread detachNewThreadWithBlock:^{
        while (!stopThread) {
            batch->drain();
        }
    }];

    for(int i = 0; i < 500000; i++) {
        batch->add(std::make_unique<SpanData>(@"", 0));
    }
    
    stopThread = true;
    [NSThread sleepForTimeInterval:0.1];
}

@end
