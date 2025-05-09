//
//  BugsnagPerformanceSpanTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Robert B on 08/05/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import <BugsnagPerformance/BugsnagPerformance.h>
#import "../../Sources/BugsnagPerformance/Private/BugsnagPerformanceConfiguration+Private.h"
#import "BugsnagPerformanceSpan+Private.h"

static BugsnagPerformanceSpan *createSpan(TraceId traceId, SpanId spanId, double samplingProbability) {
    MetricsOptions metricsOptions;
    return [[BugsnagPerformanceSpan alloc] initWithName:@"test"
                                                traceId:traceId
                                                 spanId:spanId
                                               parentId:0
                                              startTime:SpanOptions().startTime
                                             firstClass:BSGTriStateNo
                                    samplingProbability:samplingProbability
                                    attributeCountLimit:128
                                         metricsOptions:metricsOptions
                                           onSpanEndSet:^(BugsnagPerformanceSpan * _Nonnull) {}
                                           onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}
                                          onSpanBlocked:^BugsnagPerformanceSpanCondition * _Nullable(BugsnagPerformanceSpan * _Nonnull, NSTimeInterval) { return nil; }];
}

@interface BugsnagPerformanceSpanTests : XCTestCase

@end

@implementation BugsnagPerformanceSpanTests

- (void)testEncodeAsTraceParentWhenSampled {
    TraceId traceId = {.hi = 11552827605570181403U, .lo = 13932496860624619763U};
    SpanId spanId = 17201634615767212421U;
    
    BugsnagPerformanceSpan *span = createSpan(traceId, spanId, 0.9);
    XCTAssertEqualObjects([span encodedAsTraceParent], @"00-a053e37f6d56591bc15a2c13c3c688f3-eeb87b8b7cde2185-01");
}

- (void)testEncodeAsTraceParentWhenNotSampled {
    TraceId traceId = {.hi = 11552827605570181403U, .lo = 13932496860624619763U};
    SpanId spanId = 17201634615767212421U;
    
    BugsnagPerformanceSpan *span = createSpan(traceId, spanId, 0.0);
    XCTAssertEqualObjects([span encodedAsTraceParent], @"00-a053e37f6d56591bc15a2c13c3c688f3-eeb87b8b7cde2185-00");
}

- (void)testEncodeAsTraceParentWhenSamplingSetToTrue {
    TraceId traceId = {.hi = 11552827605570181403U, .lo = 13932496860624619763U};
    SpanId spanId = 17201634615767212421U;
    
    BugsnagPerformanceSpan *span = createSpan(traceId, spanId, 0.9);
    XCTAssertEqualObjects([span encodedAsTraceParentWithSampled:YES], @"00-a053e37f6d56591bc15a2c13c3c688f3-eeb87b8b7cde2185-01");
}

- (void)testEncodeAsTraceParentWhenSamplingSetToFalse {
    TraceId traceId = {.hi = 11552827605570181403U, .lo = 13932496860624619763U};
    SpanId spanId = 17201634615767212421U;
    
    BugsnagPerformanceSpan *span = createSpan(traceId, spanId, 0.9);
    XCTAssertEqualObjects([span encodedAsTraceParentWithSampled:NO], @"00-a053e37f6d56591bc15a2c13c3c688f3-eeb87b8b7cde2185-00");
}

@end
