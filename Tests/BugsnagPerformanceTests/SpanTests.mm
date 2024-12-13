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

static BugsnagPerformanceSpan *spanWithStartTime(CFAbsoluteTime startTime, SpanLifecycleCallback onEnded) {
    TraceId tid = {.value = 1};
    return [[BugsnagPerformanceSpan alloc] initWithName:@"test"
                                                traceId:tid
                                                 spanId:1
                                               parentId:0
                                              startTime:startTime
                                             firstClass:BSGFirstClassUnset
                                    attributeCountLimit:128
                                    instrumentRendering:BSGInstrumentRenderingNo
                                           onSpanEndSet:^(BugsnagPerformanceSpan *) {}
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
    [span internalSetAttribute:@"a" withValue:@(1)];
    XCTAssertEqualObjects(@(1), [span getAttribute:@"a"]);

    XCTAssertNil([span getAttribute:@"b"]);
    [span internalSetAttribute:@"b" withValue:@(2)];
    XCTAssertEqualObjects(@(1), [span getAttribute:@"a"]);
    XCTAssertEqualObjects(@(2), [span getAttribute:@"b"]);

    [span internalSetAttribute:@"a" withValue:@(2)];
    XCTAssertEqualObjects(@(2), [span getAttribute:@"a"]);
    XCTAssertEqualObjects(@(2), [span getAttribute:@"b"]);

    [span internalSetAttribute:@"a" withValue:nil];
    XCTAssertNil([span getAttribute:@"a"]);
    XCTAssertEqualObjects(@(2), [span getAttribute:@"b"]);

    [span internalSetAttribute:@"a" withValue:@(100)];
    XCTAssertEqualObjects(@(100), [span getAttribute:@"a"]);
    XCTAssertEqualObjects(@(2), [span getAttribute:@"b"]);

    [span internalSetAttribute:@"a" withValue:nil];
    [span internalSetAttribute:@"b" withValue:nil];
    XCTAssertNil([span getAttribute:@"a"]);
    XCTAssertNil([span getAttribute:@"b"]);
}

- (void)testMutability {
    auto span = spanWithStartTime(0, ^(BugsnagPerformanceSpan *) {});

    XCTAssertNil([span getAttribute:@"a"]);
    [span internalSetAttribute:@"a" withValue:@(1)];
    XCTAssertEqualObjects(@(1), [span getAttribute:@"a"]);
    [span internalSetAttribute:@"a" withValue:@(2)];
    XCTAssertEqualObjects(@(2), [span getAttribute:@"a"]);

    [span internalSetMultipleAttributes:@{@"b": @(3), @"c": @(4)}];
    XCTAssertEqualObjects(@(3), [span getAttribute:@"b"]);
    XCTAssertEqualObjects(@(4), [span getAttribute:@"c"]);

    NSDate *now = [NSDate date];
    [span updateName:@"X"];
    XCTAssertEqualObjects(@"X", span.name);
    [span updateStartTime:now];
    XCTAssertEqualObjects(now, span.startTime);
    [span updateSamplingProbability:0.5];
    XCTAssertEqual(0.5, span.samplingProbability);

    [span end];

    [span internalSetAttribute:@"a" withValue:@(3)];
    XCTAssertEqualObjects(@(2), [span getAttribute:@"a"]);

    XCTAssertNil([span getAttribute:@"x"]);
    [span internalSetAttribute:@"x" withValue:@(2)];
    XCTAssertNil([span getAttribute:@"x"]);

    [span internalSetMultipleAttributes:@{@"b": @(10), @"c": @(11)}];
    XCTAssertEqualObjects(@(3), [span getAttribute:@"b"]);
    XCTAssertEqualObjects(@(4), [span getAttribute:@"c"]);

    [span internalSetMultipleAttributes:@{@"d": @(3), @"e": @(4)}];
    XCTAssertNil([span getAttribute:@"d"]);
    XCTAssertNil([span getAttribute:@"e"]);

    NSDate *previousNow = now;
    now = [NSDate date];
    [span updateName:@"Y"];
    XCTAssertEqualObjects(@"X", span.name);
    [span updateStartTime:now];
    XCTAssertEqualObjects(previousNow, span.startTime);
    [span updateSamplingProbability:0.1];
    XCTAssertEqual(0.5, span.samplingProbability);

    span.isMutable = true;

    [span internalSetAttribute:@"a" withValue:@(3)];
    XCTAssertEqualObjects(@(3), [span getAttribute:@"a"]);

    span.isMutable = false;

    [span internalSetAttribute:@"a" withValue:@(4)];
    XCTAssertEqualObjects(@(3), [span getAttribute:@"a"]);
}

- (void)testMultithreadedAttributesAccess {
    auto span = spanWithStartTime(0, ^(BugsnagPerformanceSpan *) {});

    [NSThread detachNewThreadWithBlock:^{
        for (int i = 0; i < 10000000; i++) {
            [span internalSetMultipleAttributes:@{@"a": @(i)}];
        }
    }];

    for(int i = 0; i < 1000000; i++) {
        [span hasAttribute:@"a" withValue:@1];
    }
}

- (void)testAttributeNameSize {
    BugsnagPerformanceSpan *span = spanWithStartTime(0, ^(BugsnagPerformanceSpan *) {});
    [span setAttribute:@"1" withValue:@1];
    XCTAssertEqualObjects(span.attributes[@"1"], @1);

    NSString *name = @"12345678901234567890123456789012345678901234567890"
                     @"12345678901234567890123456789012345678901234567890"
                     @"1234567890123456789012345678";
    [span setAttribute:name withValue:@1];
    XCTAssertEqualObjects(span.attributes[name], @1);

    name = @"12345678901234567890123456789012345678901234567890"
           @"12345678901234567890123456789012345678901234567890"
           @"12345678901234567890123456789";
    [span setAttribute:name withValue:@1];
    XCTAssertNil(span.attributes[name]);
}

- (void)testTooManyAttributes {
    TraceId tid = {.value = 1};
    auto span = [[BugsnagPerformanceSpan alloc] initWithName:@"test"
                                                     traceId:tid
                                                      spanId:1
                                                    parentId:0
                                                   startTime:0
                                                  firstClass:BSGFirstClassUnset
                                         attributeCountLimit:5
                                         instrumentRendering:BSGInstrumentRenderingNo
                                                onSpanEndSet:^(BugsnagPerformanceSpan *) {}
                                                onSpanClosed:^(BugsnagPerformanceSpan *) {}];

    // Note: "bugsnag.sampling.p" is automatically added.

    [span setAttribute:@"a" withValue:@1];
    [span setAttribute:@"b" withValue:@2];
    [span setAttribute:@"c" withValue:@3];
    [span setAttribute:@"d" withValue:@4];
    [span setAttribute:@"e" withValue:@5];

    XCTAssertEqualObjects(span.attributes[@"a"], @1);
    XCTAssertEqualObjects(span.attributes[@"b"], @2);
    XCTAssertEqualObjects(span.attributes[@"c"], @3);
    XCTAssertEqualObjects(span.attributes[@"d"], @4);
    XCTAssertNil(span.attributes[@"e"]);

    [span setAttribute:@"a" withValue:@10];
    XCTAssertEqualObjects(span.attributes[@"a"], @10);

    [span setAttribute:@"b" withValue:nil];
    XCTAssertNil(span.attributes[@"b"]);
    [span setAttribute:@"e" withValue:@5];
    XCTAssertEqualObjects(span.attributes[@"e"], @5);
    [span setAttribute:@"f" withValue:@6];
    XCTAssertNil(span.attributes[@"f"]);

    [span setAttribute:@"bugsnag.sampling.p" withValue:@0.5];
    XCTAssertEqualObjects(span.attributes[@"bugsnag.sampling.p"], @0.5);
}

@end
