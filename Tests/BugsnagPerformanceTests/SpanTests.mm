//
//  SpanTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 08.05.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BugsnagPerformanceSpan+Private.h"
#import "Utils.h"

using namespace bugsnag;

@interface SpanTests : XCTestCase

@end

@implementation SpanTests

static BugsnagPerformanceSpan *spanWithStartTime(CFAbsoluteTime startTime, OnSpanEnd onEnd) {
    TraceId tid = {.value = 1};
    return [[BugsnagPerformanceSpan alloc] initWithName:@"test"
                                                traceId:tid
                                                 spanId:1
                                               parentId:0
                                              startTime:startTime
                                             firstClass:BSGFirstClassUnset
                                                  onEnd:onEnd];
}

- (void)testStartEndUnset {
    CFAbsoluteTime startTime = CFABSOLUTETIME_INVALID;
    CFAbsoluteTime endTime = startTime;
    auto span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan * _Nonnull) {});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqualWithAccuracy(span.endTime, CFAbsoluteTimeGetCurrent(), 0.001);
}

- (void)testStartNearPastEndUnset {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 0.0005;
    CFAbsoluteTime endTime = CFABSOLUTETIME_INVALID;
    auto span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan * _Nonnull) {});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqualWithAccuracy(span.endTime, CFAbsoluteTimeGetCurrent(), 0.001);
}

- (void)testStartUnsetEndNearPast {
    CFAbsoluteTime startTime = CFABSOLUTETIME_INVALID;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() - 0.0005;
    auto span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan * _Nonnull) {});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqualWithAccuracy(span.endTime, endTime, 0.001);
}

- (void)testStartUnsetEndNearFuture {
    CFAbsoluteTime startTime = CFABSOLUTETIME_INVALID;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 0.0005;
    auto span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan * _Nonnull) {});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqualWithAccuracy(span.endTime, endTime, 0.001);
}

- (void)testStartNearPastEndNearFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 0.0005;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 0.0005;
    auto span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan * _Nonnull) {});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqualWithAccuracy(span.endTime, endTime, 0.001);
}

- (void)testStartFarPastEndUnset {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 1.0;
    CFAbsoluteTime endTime = CFABSOLUTETIME_INVALID;
    auto span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan * _Nonnull) {});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqualWithAccuracy(span.endTime, CFAbsoluteTimeGetCurrent(), 0.001);
}

- (void)testStartFarPastEndNearPast {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 1.0;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() - 0.0005;
    auto span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan * _Nonnull) {});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqual(span.endTime, endTime);
}

- (void)testStartFarPastEndNearFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 1.0;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 0.0005;
    auto span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan * _Nonnull) {});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqual(span.endTime, endTime);
}

- (void)testStartNowEndFarFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 1.0;
    auto span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan * _Nonnull) {});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqual(span.endTime, endTime);
}

- (void)testStartFarPastEndFarFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 1.0;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 1.0;
    auto span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan * _Nonnull) {});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqual(span.endTime, endTime);
}

- (void)testStartNearPastEndFarFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 0.0001;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 1.0;
    auto span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan * _Nonnull) {});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqual(span.endTime, endTime);
}

- (void)testStartNearFutureEndFarFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() + 0.0001;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 1.0;
    auto span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan * _Nonnull) {});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqual(span.endTime, endTime);
}

- (void)testStartEndDistantPast {
    CFAbsoluteTime startTime = 0;
    CFAbsoluteTime endTime = 0;
    auto span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan * _Nonnull) {});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqual(span.endTime, endTime);
}

- (void)testMultithreadedAttributesAccess {
    auto span = spanWithStartTime(0, ^(BugsnagPerformanceSpan * _Nonnull) {});

    [NSThread detachNewThreadWithBlock:^{
        for (int i = 0; i < 10000000; i++) {
            [span addAttributes:@{@"a": @(i)}];
        }
    }];

    for(int i = 0; i < 1000000; i++) {
        [span hasAttribute:@"a" withValue:@1];
    }
}

@end
