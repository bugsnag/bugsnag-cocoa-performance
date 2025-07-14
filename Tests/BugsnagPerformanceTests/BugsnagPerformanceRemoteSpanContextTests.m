//
//  BugsnagPerformanceRemoteSpanContextTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Robert Bartoszewski on 07/05/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <BugsnagPerformance/BugsnagPerformance.h>

@interface BugsnagPerformanceRemoteSpanContextTests : XCTestCase

@end

@implementation BugsnagPerformanceRemoteSpanContextTests

- (void)testContextWithTraceParentStringReturnsNilIfTheStringIsEmpty {
    XCTAssertNil([BugsnagPerformanceRemoteSpanContext contextWithTraceParentString:@""]);
}

- (void)testContextWithTraceParentStringReturnsNilIfTheStringDoesntContainEnoughComponents {
    XCTAssertNil([BugsnagPerformanceRemoteSpanContext contextWithTraceParentString:@"0-0-0"]);
}

- (void)testContextWithTraceParentStringReturnsNilIfTheIdsArentTooShort {
    XCTAssertNil([BugsnagPerformanceRemoteSpanContext contextWithTraceParentString:@"0-032432414-0324234-0"]);
}

- (void)testContextWithTraceParentStringReturnsNilIfTheIdsArentHex {
    XCTAssertNil([BugsnagPerformanceRemoteSpanContext contextWithTraceParentString:@"00-a053e37f6d56591zc15a2c13c3c6ttfq-eeb87b8b7cdz2185-01"]);
}

- (void)testContextWithTraceParentStringReturnsNilIfTheIdsContainUppercaseLetters {
    XCTAssertNil([BugsnagPerformanceRemoteSpanContext contextWithTraceParentString:@"00-A053E37F6D56591BC15A2C13C3C688F3-EEB87B8B7CDE2185-01"]);
}


- (void)testContextWithTraceParentStringReturnsAContextForAllZeros {
    BugsnagPerformanceSpanContext *context = [BugsnagPerformanceRemoteSpanContext contextWithTraceParentString:@"00-00000000000000000000000000000000-0000000000000000-00"];
    TraceId traceId = {.hi = 0, .lo = 0};
    XCTAssertNotNil(context);
    XCTAssertEqual(context.traceId.hi, traceId.hi);
    XCTAssertEqual(context.traceId.lo, traceId.lo);
    XCTAssertEqual(context.traceId.value, traceId.value);
    XCTAssertEqual(context.spanId, 0);
}

- (void)testContextWithTraceParentStringReturnsAContextForMaxValue {
    BugsnagPerformanceSpanContext *context = [BugsnagPerformanceRemoteSpanContext contextWithTraceParentString:@"00-ffffffffffffffffffffffffffffffff-ffffffffffffffff-00"];
    TraceId traceId = {.hi = UINT64_MAX, .lo = UINT64_MAX};
    XCTAssertNotNil(context);
    XCTAssertEqual(context.traceId.hi, traceId.hi);
    XCTAssertEqual(context.traceId.lo, traceId.lo);
    XCTAssertEqual(context.traceId.value, traceId.value);
    XCTAssertEqual(context.spanId, UINT64_MAX);
}

- (void)testContextWithTraceParentStringReturnsAContextForValues {
    BugsnagPerformanceSpanContext *context = [BugsnagPerformanceRemoteSpanContext contextWithTraceParentString:@"00-a053e37f6d56591bc15a2c13c3c688f3-eeb87b8b7cde2185-01"];
    TraceId traceId = {.hi = 11552827605570181403U, .lo = 13932496860624619763U};
    SpanId spanId = 17201634615767212421U;
    XCTAssertNotNil(context);
    XCTAssertEqual(context.traceId.hi, traceId.hi);
    XCTAssertEqual(context.traceId.lo, traceId.lo);
    XCTAssertEqual(context.traceId.value, traceId.value);
    XCTAssertEqual(context.spanId, spanId);
}

- (void)testContextWithTraceParentEncodesToTheSameTraceParent {
    NSString *traceparentString = @"00-a053e37f6d56591bc15a2c13c3c688f3-eeb87b8b7cde2185-01";
    BugsnagPerformanceSpanContext *context = [BugsnagPerformanceRemoteSpanContext contextWithTraceParentString:traceparentString];
    XCTAssertNotNil(context);
    XCTAssertEqualObjects([context encodedAsTraceParent], traceparentString);
}

@end
