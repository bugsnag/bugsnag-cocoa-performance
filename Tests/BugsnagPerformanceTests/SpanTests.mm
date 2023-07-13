//
//  SpanTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 08.05.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Span.h"
#import "SpanData.h"

using namespace bugsnag;

@interface SpanTests : XCTestCase

@end

@implementation SpanTests

static std::shared_ptr<Span> spanWithStartTime(CFAbsoluteTime startTime, OnSpanEnd onEnd) {
    TraceId tid = {.value = 1};
    return std::make_shared<Span>(@"test", tid, 1, 0, startTime, BSGFirstClassUnset, onEnd);
}

- (void)testStartEndUnset {
    CFAbsoluteTime startTime = CFABSOLUTETIME_INVALID;
    CFAbsoluteTime endTime = startTime;
    __block std::shared_ptr<SpanData> spanData = nullptr;
    auto span = spanWithStartTime(startTime, ^(std::shared_ptr<SpanData> data) {spanData = data;});
    span->end(endTime);
    XCTAssertEqualWithAccuracy(spanData->endTime, CFAbsoluteTimeGetCurrent(), 0.001);
}

- (void)testStartEndUnset2 {
    CFAbsoluteTime startTime = CFABSOLUTETIME_INVALID;
    CFAbsoluteTime endTime = startTime;
    __block std::shared_ptr<SpanData> spanData = nullptr;
    auto span = spanWithStartTime(startTime, ^(std::shared_ptr<SpanData> data) {spanData = data;});
    sleep(1);
    span->end(endTime);
    XCTAssertEqualWithAccuracy(spanData->endTime, CFAbsoluteTimeGetCurrent(), 0.001);
}

- (void)testStartNearPastEndUnset {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 0.0005;
    CFAbsoluteTime endTime = CFABSOLUTETIME_INVALID;
    __block std::shared_ptr<SpanData> spanData = nullptr;
    auto span = spanWithStartTime(startTime, ^(std::shared_ptr<SpanData> data) {spanData = data;});
    span->end(endTime);
    XCTAssertEqualWithAccuracy(spanData->endTime, CFAbsoluteTimeGetCurrent(), 0.001);
}

- (void)testStartUnsetEndNearPast {
    CFAbsoluteTime startTime = CFABSOLUTETIME_INVALID;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() - 0.0005;
    __block std::shared_ptr<SpanData> spanData = nullptr;
    auto span = spanWithStartTime(startTime, ^(std::shared_ptr<SpanData> data) {spanData = data;});
    span->end(endTime);
    XCTAssertEqualWithAccuracy(spanData->endTime, endTime, 0.001);
}

- (void)testStartUnsetEndNearFuture {
    CFAbsoluteTime startTime = CFABSOLUTETIME_INVALID;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 0.0005;
    __block std::shared_ptr<SpanData> spanData = nullptr;
    auto span = spanWithStartTime(startTime, ^(std::shared_ptr<SpanData> data) {spanData = data;});
    span->end(endTime);
    XCTAssertEqualWithAccuracy(spanData->endTime, endTime, 0.001);
}

- (void)testStartNearPastEndNearFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 0.0005;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 0.0005;
    __block std::shared_ptr<SpanData> spanData = nullptr;
    auto span = spanWithStartTime(startTime, ^(std::shared_ptr<SpanData> data) {spanData = data;});
    span->end(endTime);
    XCTAssertEqualWithAccuracy(spanData->endTime, endTime, 0.001);
}

- (void)testStartFarPastEndUnset {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 1.0;
    CFAbsoluteTime endTime = CFABSOLUTETIME_INVALID;
    __block std::shared_ptr<SpanData> spanData = nullptr;
    auto span = spanWithStartTime(startTime, ^(std::shared_ptr<SpanData> data) {spanData = data;});
    span->end(endTime);
    XCTAssertEqualWithAccuracy(spanData->endTime, CFAbsoluteTimeGetCurrent(), 0.001);
}

- (void)testStartFarPastEndNearPast {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 1.0;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() - 0.0005;
    __block std::shared_ptr<SpanData> spanData = nullptr;
    auto span = spanWithStartTime(startTime, ^(std::shared_ptr<SpanData> data) {spanData = data;});
    span->end(endTime);
    XCTAssertEqual(spanData->endTime, endTime);
}

- (void)testStartFarPastEndNearFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 1.0;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 0.0005;
    __block std::shared_ptr<SpanData> spanData = nullptr;
    auto span = spanWithStartTime(startTime, ^(std::shared_ptr<SpanData> data) {spanData = data;});
    span->end(endTime);
    XCTAssertEqual(spanData->endTime, endTime);
}

- (void)testStartNowEndFarFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 1.0;
    __block std::shared_ptr<SpanData> spanData = nullptr;
    auto span = spanWithStartTime(startTime, ^(std::shared_ptr<SpanData> data) {spanData = data;});
    span->end(endTime);
    XCTAssertEqual(spanData->endTime, endTime);
}

- (void)testStartFarPastEndFarFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 1.0;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 1.0;
    __block std::shared_ptr<SpanData> spanData = nullptr;
    auto span = spanWithStartTime(startTime, ^(std::shared_ptr<SpanData> data) {spanData = data;});
    span->end(endTime);
    XCTAssertEqual(spanData->endTime, endTime);
}

- (void)testStartNearPastEndFarFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() - 0.0001;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 1.0;
    __block std::shared_ptr<SpanData> spanData = nullptr;
    auto span = spanWithStartTime(startTime, ^(std::shared_ptr<SpanData> data) {spanData = data;});
    span->end(endTime);
    XCTAssertEqual(spanData->endTime, endTime);
}

- (void)testStartNearFutureEndFarFuture {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent() + 0.0001;
    CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent() + 1.0;
    __block std::shared_ptr<SpanData> spanData = nullptr;
    auto span = spanWithStartTime(startTime, ^(std::shared_ptr<SpanData> data) {spanData = data;});
    span->end(endTime);
    XCTAssertEqual(spanData->endTime, endTime);
}

- (void)testStartEndDistantPast {
    CFAbsoluteTime startTime = 0;
    CFAbsoluteTime endTime = 0;
    __block std::shared_ptr<SpanData> spanData = nullptr;
    auto span = spanWithStartTime(startTime, ^(std::shared_ptr<SpanData> data) {spanData = data;});
    span->end(endTime);
    XCTAssertEqual(spanData->endTime, endTime);
}

- (void)testMultithreadedAttributesAccess {
    auto span = spanWithStartTime(0, ^(std::shared_ptr<SpanData>) {});

    [NSThread detachNewThreadWithBlock:^{
        for (int i = 0; i < 10000000; i++) {
            span->addAttributes(@{@"a": @(i)});
        }
    }];

    for(int i = 0; i < 1000000; i++) {
        span->hasAttribute(@"a", @1);
    }
}

@end
