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

static BugsnagPerformanceSpan *spanWithStartTime(CFAbsoluteTime startTime, OnSpanClosed onEnded) {
    TraceId tid = {.value = 1};
    return [[BugsnagPerformanceSpan alloc] initWithName:@"test"
                                                traceId:tid
                                                 spanId:1
                                               parentId:0
                                              startTime:startTime
                                             firstClass:BSGFirstClassUnset
                                            onSpanClosed:onEnded];
}

- (void)testStartEndUnset {
    CFAbsoluteTime startTime = CFABSOLUTETIME_INVALID;
    CFAbsoluteTime endTime = startTime;
    __block BugsnagPerformanceSpan *foundSpan= nil;
    BugsnagPerformanceSpan *span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan *cbSpan) {foundSpan = cbSpan;});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqualWithAccuracy(span.endAbsTime, CFAbsoluteTimeGetCurrent(), 0.001);
}

- (void)testStartNearPastEndUnset {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 0.0005;
    CFAbsoluteTime endTime = CFABSOLUTETIME_INVALID;
    __block BugsnagPerformanceSpan *foundSpan= nil;
    BugsnagPerformanceSpan *span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan *cbSpan) {foundSpan = cbSpan;});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqualWithAccuracy(span.endAbsTime, CFAbsoluteTimeGetCurrent(), 0.001);
}

- (void)testStartUnsetEndNearPast {
    CFAbsoluteTime startTime = CFABSOLUTETIME_INVALID;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() - 0.0005;
    __block BugsnagPerformanceSpan *foundSpan= nil;
    BugsnagPerformanceSpan *span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan *cbSpan) {foundSpan = cbSpan;});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqualWithAccuracy(span.endAbsTime, endTime, 0.001);
}

- (void)testStartUnsetEndNearFuture {
    CFAbsoluteTime startTime = CFABSOLUTETIME_INVALID;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 0.0005;
    __block BugsnagPerformanceSpan *foundSpan= nil;
    BugsnagPerformanceSpan *span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan *cbSpan) {foundSpan = cbSpan;});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqualWithAccuracy(span.endAbsTime, endTime, 0.001);
}

- (void)testStartNearPastEndNearFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 0.0005;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 0.0005;
    __block BugsnagPerformanceSpan *foundSpan= nil;
    BugsnagPerformanceSpan *span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan *cbSpan) {foundSpan = cbSpan;});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqualWithAccuracy(span.endAbsTime, endTime, 0.001);
}

- (void)testStartFarPastEndUnset {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 1.0;
    CFAbsoluteTime endTime = CFABSOLUTETIME_INVALID;
    __block BugsnagPerformanceSpan *foundSpan= nil;
    BugsnagPerformanceSpan *span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan *cbSpan) {foundSpan = cbSpan;});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqualWithAccuracy(span.endAbsTime, CFAbsoluteTimeGetCurrent(), 0.001);
}

- (void)testStartFarPastEndNearPast {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 1.0;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() - 0.0005;
    __block BugsnagPerformanceSpan *foundSpan= nil;
    BugsnagPerformanceSpan *span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan *cbSpan) {foundSpan = cbSpan;});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqual(span.endAbsTime, endTime);
}

- (void)testStartFarPastEndNearFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 1.0;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 0.0005;
    __block BugsnagPerformanceSpan *foundSpan= nil;
    BugsnagPerformanceSpan *span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan *cbSpan) {foundSpan = cbSpan;});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqual(span.endAbsTime, endTime);
}

- (void)testStartNowEndFarFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 1.0;
    __block BugsnagPerformanceSpan *foundSpan= nil;
    BugsnagPerformanceSpan *span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan *cbSpan) {foundSpan = cbSpan;});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqual(span.endAbsTime, endTime);
}

- (void)testStartFarPastEndFarFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 1.0;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 1.0;
    __block BugsnagPerformanceSpan *foundSpan= nil;
    BugsnagPerformanceSpan *span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan *cbSpan) {foundSpan = cbSpan;});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqual(span.endAbsTime, endTime);
}

- (void)testStartNearPastEndFarFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 0.0001;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 1.0;
    __block BugsnagPerformanceSpan *foundSpan= nil;
    BugsnagPerformanceSpan *span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan *cbSpan) {foundSpan = cbSpan;});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqual(span.endAbsTime, endTime);
}

- (void)testStartNearFutureEndFarFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() + 0.0001;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 1.0;
    __block BugsnagPerformanceSpan *foundSpan= nil;
    BugsnagPerformanceSpan *span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan *cbSpan) {foundSpan = cbSpan;});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqual(span.endAbsTime, endTime);
}

- (void)testStartEndDistantPast {
    CFAbsoluteTime startTime = 0;
    CFAbsoluteTime endTime = 0;
    __block BugsnagPerformanceSpan *foundSpan= nil;
    BugsnagPerformanceSpan *span = spanWithStartTime(startTime, ^(BugsnagPerformanceSpan *cbSpan) {foundSpan = cbSpan;});
    [span endWithAbsoluteTime:endTime];
    XCTAssertEqual(span.endAbsTime, endTime);
}

- (void)testAddRemoveAttributes {
    auto span = spanWithStartTime(0, ^(BugsnagPerformanceSpan *) {});

    XCTAssertNil([span getAttribute:@"a"]);
    [span setAttribute:@"a" withValue:@(1)];
    XCTAssertEqualObjects(@(1), [span getAttribute:@"a"]);

    XCTAssertNil([span getAttribute:@"b"]);
    [span setAttribute:@"b" withValue:@(2)];
    XCTAssertEqualObjects(@(1), [span getAttribute:@"a"]);
    XCTAssertEqualObjects(@(2), [span getAttribute:@"b"]);

    [span setAttribute:@"a" withValue:@(2)];
    XCTAssertEqualObjects(@(2), [span getAttribute:@"a"]);
    XCTAssertEqualObjects(@(2), [span getAttribute:@"b"]);

    [span setAttribute:@"a" withValue:nil];
    XCTAssertNil([span getAttribute:@"a"]);
    XCTAssertEqualObjects(@(2), [span getAttribute:@"b"]);

    [span setAttribute:@"a" withValue:@(100)];
    XCTAssertEqualObjects(@(100), [span getAttribute:@"a"]);
    XCTAssertEqualObjects(@(2), [span getAttribute:@"b"]);

    [span setAttribute:@"a" withValue:nil];
    [span setAttribute:@"b" withValue:nil];
    XCTAssertNil([span getAttribute:@"a"]);
    XCTAssertNil([span getAttribute:@"b"]);
}

- (void)testMultithreadedAttributesAccess {
    auto span = spanWithStartTime(0, ^(BugsnagPerformanceSpan *) {});

    [NSThread detachNewThreadWithBlock:^{
        for (int i = 0; i < 10000000; i++) {
            [span setMultipleAttributes:@{@"a": @(i)}];
        }
    }];

    for(int i = 0; i < 1000000; i++) {
        [span hasAttribute:@"a" withValue:@1];
    }
}

@end
