//
//  SpanStackingHandlerTests.mm
//  BugsnagPerformance-iOSTests
//
//  Created by Robert B on 25/05/2023.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "IdGenerator.h"
#import "SpanOptions.h"
#import "SpanStackingHandler.h"
#import "BugsnagPerformanceSpan+Private.h"
#import <memory>

using namespace bugsnag;

static BugsnagPerformanceSpan *createSpan(std::shared_ptr<SpanStackingHandler> handler) {
    MetricsOptions metricsOptions;
    return [[BugsnagPerformanceSpan alloc] initWithName:@"test"
                                                traceId:IdGenerator::generateTraceId()
                                                 spanId:IdGenerator::generateSpanId()
                                               parentId:IdGenerator::generateSpanId()
                                              startTime:SpanOptions().startTime
                                             firstClass:BSGTriStateNo
                                    attributeCountLimit:128
                                         metricsOptions:metricsOptions
                                           onSpanEndSet:^(BugsnagPerformanceSpan * _Nonnull) {}
                                           onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull span) {
        handler->onSpanClosed(span.spanId);
    }];
}

@interface SpanStackingHandlerTests : XCTestCase

@end

@implementation SpanStackingHandlerTests

- (void)testCurrentSpanShouldReturnTheFirstStartedSpan {
    auto handler = std::make_shared<SpanStackingHandler>();
    BugsnagPerformanceSpan *span = createSpan(handler);
    handler->push(span);
    XCTAssertEqual(handler->currentSpan().spanId, span.spanId);
    XCTAssertFalse(handler->unitTest_isEmpty());
}

- (void)testCurrentSpanShouldReturnNilIfNoSpanIsActive {
    auto handler = std::make_shared<SpanStackingHandler>();
    XCTAssertNil(handler->currentSpan());
    XCTAssertTrue(handler->unitTest_isEmpty());
}

- (void)testCurrentSpanShouldReturnNilIfThereWasOneSpanAndItEnded {
    auto handler = std::make_shared<SpanStackingHandler>();
    BugsnagPerformanceSpan *span = createSpan(handler);
    handler->push(span);
    [span end];
    XCTAssertNil(handler->currentSpan());
    XCTAssertTrue(handler->unitTest_isEmpty());
}

- (void)testCurrentSpanShouldUpdateAsTheSpansStartAndEndInSequence {
    auto handler = std::make_shared<SpanStackingHandler>();
    BugsnagPerformanceSpan *span1 = createSpan(handler);
    BugsnagPerformanceSpan *span2 = createSpan(handler);
    BugsnagPerformanceSpan *span3 = createSpan(handler);
    handler->push(span1);
    XCTAssertEqual(handler->currentSpan().spanId, span1.spanId);
    handler->push(span2);
    XCTAssertEqual(handler->currentSpan().spanId, span2.spanId);
    handler->push(span3);
    XCTAssertEqual(handler->currentSpan().spanId, span3.spanId);
    
    [span3 end];
    XCTAssertEqual(handler->currentSpan().spanId, span2.spanId);
    [span2 end];
    XCTAssertEqual(handler->currentSpan().spanId, span1.spanId);
    [span1 end];
    
    XCTAssertNil(handler->currentSpan());
    XCTAssertTrue(handler->unitTest_isEmpty());
}

- (void)testCurrentSpanShouldUpdateAsTheSpansStartAndEndInReverseSequence {
    auto handler = std::make_shared<SpanStackingHandler>();
    BugsnagPerformanceSpan *span1 = createSpan(handler);
    BugsnagPerformanceSpan *span2 = createSpan(handler);
    BugsnagPerformanceSpan *span3 = createSpan(handler);
    handler->push(span1);
    handler->push(span2);
    handler->push(span3);
    
    [span1 end];
    XCTAssertEqual(handler->currentSpan().spanId, span3.spanId);
    [span2 end];
    XCTAssertEqual(handler->currentSpan().spanId, span3.spanId);
    [span3 end];
    
    XCTAssertNil(handler->currentSpan());
    XCTAssertTrue(handler->unitTest_isEmpty());
}

- (void)testCurrentSpanShouldUpdateAsTheSpansStartAndMiddleSpanEnds {
    auto handler = std::make_shared<SpanStackingHandler>();
    BugsnagPerformanceSpan *span1 = createSpan(handler);
    BugsnagPerformanceSpan *span2 = createSpan(handler);
    BugsnagPerformanceSpan *span3 = createSpan(handler);
    handler->push(span1);
    handler->push(span2);
    handler->push(span3);
    
    [span2 end];
    XCTAssertEqual(handler->currentSpan().spanId, span3.spanId);
    [span3 end];
    XCTAssertEqual(handler->currentSpan().spanId, span1.spanId);
    [span1 end];
    
    XCTAssertNil(handler->currentSpan());
    XCTAssertTrue(handler->unitTest_isEmpty());
}

- (void)testCurrentSpanShouldUpdateTraversingDispatchQueue {
    auto handler = std::make_shared<SpanStackingHandler>();
    XCTestExpectation *expectation = [XCTestExpectation new];
    BugsnagPerformanceSpan *span1 = createSpan(handler);
    BugsnagPerformanceSpan *span2 = createSpan(handler);
    BugsnagPerformanceSpan *span3 = createSpan(handler);
    handler->push(span1);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        XCTAssertEqual(handler->currentSpan().spanId, span1.spanId);
        handler->push(span2);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            XCTAssertEqual(handler->currentSpan().spanId, span2.spanId);
            [span2 end];
            XCTAssertEqual(handler->currentSpan().spanId, span1.spanId);
            handler->push(span3);
            XCTAssertEqual(handler->currentSpan().spanId, span3.spanId);
            [expectation fulfill];
        });
    });
    
    [self waitForExpectations:@[expectation] timeout:1.0];
    XCTAssertEqual(handler->currentSpan().spanId, span1.spanId);
    [span3 end];
    XCTAssertEqual(handler->currentSpan().spanId, span1.spanId);
    [span1 end];
    XCTAssertNil(handler->currentSpan());
    XCTAssertTrue(handler->unitTest_isEmpty());
}

- (void)testCurrentSpanEndingShouldTraverseDispatchQueue {
    auto handler = std::make_shared<SpanStackingHandler>();
    XCTestExpectation *expectation = [XCTestExpectation new];
    @autoreleasepool {
        BugsnagPerformanceSpan *span1 = createSpan(handler);
        BugsnagPerformanceSpan *span2 = createSpan(handler);
        handler->push(span1);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            XCTAssertEqual(handler->currentSpan().spanId, span1.spanId);
            handler->push(span2);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                XCTAssertEqual(handler->currentSpan().spanId, span2.spanId);
                [span1 end];
                XCTAssertEqual(handler->currentSpan().spanId, span2.spanId);
                [expectation fulfill];
            });
        });
    }
    
    [self waitForExpectations:@[expectation] timeout:1.0];
    XCTAssertNil(handler->currentSpan());
    XCTAssertTrue(handler->unitTest_isEmpty());
}

- (void)testCurrentSpanShouldUpdateNotTraversingDetatchedThreads {
    auto handler = std::make_shared<SpanStackingHandler>();
    XCTestExpectation *expectation = [XCTestExpectation new];
    BugsnagPerformanceSpan *span1 = createSpan(handler);
    BugsnagPerformanceSpan *span2 = createSpan(handler);
    handler->push(span1);
    [NSThread detachNewThreadWithBlock:^{
        usleep(100000);
        XCTAssertNil(handler->currentSpan());
        handler->push(span2);
        XCTAssertEqual(handler->currentSpan().spanId, span2.spanId);
        [expectation fulfill];
    }];
    
    [self waitForExpectations:@[expectation] timeout:1.0];
    XCTAssertEqual(handler->currentSpan().spanId, span1.spanId);
    [span2 end];
    XCTAssertEqual(handler->currentSpan().spanId, span1.spanId);
    [span1 end];
    XCTAssertNil(handler->currentSpan());
    XCTAssertTrue(handler->unitTest_isEmpty());
}

- (void)testCurrentSpanShouldReturnNilIfTheCreatedSpanWasDumped {
    auto handler = std::make_shared<SpanStackingHandler>();
    @autoreleasepool {
        BugsnagPerformanceSpan *span = createSpan(handler);
        handler->push(span);
        XCTAssertEqual(handler->currentSpan().spanId, span.spanId);
    }
    XCTAssertNil(handler->currentSpan());
    XCTAssertTrue(handler->unitTest_isEmpty());
}

- (void)testHasSpanWithAttributeShouldReturnFalseWhenTheStackIsEmpty {
    auto handler = std::make_shared<SpanStackingHandler>();
    XCTAssertFalse(handler->hasSpanWithAttribute(@"testAttribute", @"testValue"));
}

- (void)testHasSpanWithAttributeShouldReturnTrueWhenThereIsOneSpanWithTheAttribute {
    auto handler = std::make_shared<SpanStackingHandler>();
    BugsnagPerformanceSpan *span = createSpan(handler);
    [span internalSetMultipleAttributes:@{@"testAttribute": @"testValue"}];
    handler->push(span);
    XCTAssertTrue(handler->hasSpanWithAttribute(@"testAttribute", @"testValue"));
    
}

- (void)testHasSpanWithAttributeShouldReturnTrueWhenTheAttributeIsFurtherInTheStack {
    auto handler = std::make_shared<SpanStackingHandler>();
    BugsnagPerformanceSpan *span1 = createSpan(handler);
    BugsnagPerformanceSpan *span2 = createSpan(handler);
    BugsnagPerformanceSpan *span3 = createSpan(handler);
    [span2 internalSetMultipleAttributes:@{@"testAttribute": @"testValue"}];
    handler->push(span1);
    handler->push(span2);
    handler->push(span3);
    XCTAssertTrue(handler->hasSpanWithAttribute(@"testAttribute", @"testValue"));
}

- (void)testHasSpanWithAttributeShouldReturnFalseWhenThereAreNoSpansWithTheAttribute {
    auto handler = std::make_shared<SpanStackingHandler>();
    BugsnagPerformanceSpan *span1 = createSpan(handler);
    BugsnagPerformanceSpan *span2 = createSpan(handler);
    BugsnagPerformanceSpan *span3 = createSpan(handler);
    [span2 internalSetMultipleAttributes:@{@"otherTestAttribute": @"testValue"}];
    handler->push(span1);
    handler->push(span2);
    handler->push(span3);
    XCTAssertFalse(handler->hasSpanWithAttribute(@"testAttribute", @"testValue"));
}

- (void)testHasSpanWithAttributeShouldReturnFalseWhenThereAreNoSpansWithTheAttributeValue {
    auto handler = std::make_shared<SpanStackingHandler>();
    BugsnagPerformanceSpan *span1 = createSpan(handler);
    BugsnagPerformanceSpan *span2 = createSpan(handler);
    BugsnagPerformanceSpan *span3 = createSpan(handler);
    [span2 internalSetMultipleAttributes:@{@"testAttribute": @"otherTestValue"}];
    handler->push(span1);
    handler->push(span2);
    handler->push(span3);
    XCTAssertFalse(handler->hasSpanWithAttribute(@"testAttribute", @"testValue"));
}

- (void)testHasSpanWithAttributeShouldReturnFalseWhenTheSpanWithTheAttributeHasEnded {
    auto handler = std::make_shared<SpanStackingHandler>();
    BugsnagPerformanceSpan *span1 = createSpan(handler);
    BugsnagPerformanceSpan *span2 = createSpan(handler);
    BugsnagPerformanceSpan *span3 = createSpan(handler);
    [span2 internalSetMultipleAttributes:@{@"testAttribute": @"testValue"}];
    handler->push(span1);
    handler->push(span2);
    handler->push(span3);
    
    [span2 end];
    XCTAssertFalse(handler->hasSpanWithAttribute(@"testAttribute", @"testValue"));
}

- (void)testCurrentSpanShouldPerformWellInStressTestWithThreads {
    auto handler = std::make_shared<SpanStackingHandler>();
    XCTestExpectation *expectation1 = [XCTestExpectation new];
    XCTestExpectation *expectation2 = [XCTestExpectation new];
    XCTestExpectation *expectation3 = [XCTestExpectation new];
    
    [NSThread detachNewThreadWithBlock:^{
        for (NSUInteger i = 0; i < 10000; i++) {
            auto span = createSpan(handler);
            handler->push(span);
            [span end];
        }
        
        [NSThread detachNewThreadWithBlock:^{
            @autoreleasepool {
                for (NSUInteger i = 0; i < 10000; i++) {
                    auto span = createSpan(handler);
                    handler->push(span);
                }
            }
            [expectation1 fulfill];
        }];
        [expectation2 fulfill];
    }];
    
    [NSThread detachNewThreadWithBlock:^{
        NSMutableArray<BugsnagPerformanceSpan *> *spans = [@[] mutableCopy];
        for (NSUInteger i = 0; i < 10000; i++) {
            auto span = createSpan(handler);
            handler->push(span);
            [spans addObject:span];
        }
        
        for (NSUInteger i = 0; i < 10000; i++) {
            [spans[i] end];
        }
        [expectation3 fulfill];
    }];
    
    [self waitForExpectations:@[expectation1, expectation2, expectation3] timeout:10.0];
    XCTAssertTrue(handler->unitTest_isEmpty());
}

- (void)testCurrentSpanShouldPerformWellInStressTestWithQueues {
    auto handler = std::make_shared<SpanStackingHandler>();
    XCTestExpectation *expectation1 = [XCTestExpectation new];
    XCTestExpectation *expectation2 = [XCTestExpectation new];
    XCTestExpectation *expectation3 = [XCTestExpectation new];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSUInteger i = 0; i < 10000; i++) {
            auto span = createSpan(handler);
            handler->push(span);
            [span end];
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @autoreleasepool {
                for (NSUInteger i = 0; i < 10000; i++) {
                    auto span = createSpan(handler);
                    handler->push(span);
                }
            }
            [expectation1 fulfill];
        });
        [expectation2 fulfill];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray<BugsnagPerformanceSpan *> *spans = [@[] mutableCopy];
        for (NSUInteger i = 0; i < 10000; i++) {
            auto span = createSpan(handler);
            handler->push(span);
            [spans addObject:span];
        }
        
        for (NSUInteger i = 0; i < 10000; i++) {
            [spans[i] end];
        }
        [expectation3 fulfill];
    });
    
    [self waitForExpectations:@[expectation1, expectation2, expectation3] timeout:10.0];
    XCTAssertTrue(handler->unitTest_isEmpty());
}

@end
