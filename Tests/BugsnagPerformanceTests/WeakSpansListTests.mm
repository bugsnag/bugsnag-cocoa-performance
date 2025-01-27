//
//  WeakSpansListTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 08.12.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "WeakSpansList.h"
#import "BugsnagPerformanceSpan+Private.h"
#import "SpanOptions.h"
#import "IdGenerator.h"

using namespace bugsnag;

@interface WeakSpansListTests : XCTestCase

@end

static BugsnagPerformanceSpan *createSpan() {
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
                                           onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {
    }];
}

@implementation WeakSpansListTests

- (void)testAllReleased {
    WeakSpansList list;
    @autoreleasepool {
        list.add(createSpan());
        list.add(createSpan());
        list.add(createSpan());
    }
    XCTAssertEqual(3U, list.count());
    list.compact();
    XCTAssertEqual(0U, list.count());
}

- (void)testNoneReleased {
    WeakSpansList list;
    list.add(createSpan());
    list.add(createSpan());
    list.add(createSpan());
    XCTAssertEqual(3U, list.count());
    list.compact();
    XCTAssertEqual(3U, list.count());
}

- (void)testSomeReleased {
    WeakSpansList list;
    list.add(createSpan());
    @autoreleasepool {
        list.add(createSpan());
        list.add(createSpan());
        list.add(createSpan());
    }
    list.add(createSpan());
    XCTAssertEqual(5U, list.count());
    list.compact();
    XCTAssertEqual(2U, list.count());
}

@end
