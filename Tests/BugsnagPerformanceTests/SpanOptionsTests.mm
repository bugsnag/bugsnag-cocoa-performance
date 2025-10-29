//
//  SpanOptionsTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 16.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BugsnagPerformance/BugsnagPerformanceSpan.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanOptions.h>
#import "SpanOptions.h"
#import "BugsnagPerformanceSpan+Private.h"
#import "IdGenerator.h"
#import "BugsnagPerformanceSpanCondition+Private.h"
#import "BugsnagPerformanceSpanContext+Private.h"
#import <memory>

using namespace bugsnag;

@interface SpanOptionsTests : XCTestCase

@end


@implementation SpanOptionsTests

- (void)testUnset {
    BugsnagPerformanceSpanOptions *objcOptions = [BugsnagPerformanceSpanOptions new];
    XCTAssertEqual(objcOptions.parentContext, [BugsnagPerformanceSpanContext defaultContext]);
    XCTAssertNil(objcOptions.startTime);
    XCTAssertTrue(objcOptions.makeCurrentContext);
    XCTAssertEqual(objcOptions.firstClass, BSGTriStateUnset);
}

- (void)testConversionDefaults {
    BugsnagPerformanceSpanOptions *objcOptions = [BugsnagPerformanceSpanOptions new];
    SpanOptions cOptions(objcOptions);
    XCTAssertEqual(cOptions.parentContext, [BugsnagPerformanceSpanContext defaultContext]);
    XCTAssertTrue(isnan(cOptions.startTime));
    XCTAssertTrue(cOptions.makeCurrentContext);
    XCTAssertEqual(cOptions.firstClass, BSGTriStateUnset);
}

- (void)testSettingParentContext {
    BugsnagPerformanceSpanOptions *objcOptions = [BugsnagPerformanceSpanOptions new];
    XCTAssertEqual(objcOptions.parentContext, [BugsnagPerformanceSpanContext defaultContext]);
    [objcOptions setParentContext:nil];
    XCTAssertNil(objcOptions.parentContext);

    SpanOptions cOptions(objcOptions);
    XCTAssertNil(objcOptions.parentContext);

    SpanOptions cOptions2;
    XCTAssertEqual(cOptions2.parentContext, [BugsnagPerformanceSpanContext defaultContext]);
    cOptions2.parentContext = nil;
    XCTAssertNil(cOptions2.parentContext);
}

- (void)testConversion {
    MetricsOptions metricsOptions;
    metricsOptions.rendering = BSGTriStateNo;
    BugsnagPerformanceSpan *span = [[BugsnagPerformanceSpan alloc] initWithName:@"test"
                                                                        traceId:IdGenerator::generateTraceId()
                                                                         spanId:IdGenerator::generateSpanId()
                                                                       parentId:IdGenerator::generateSpanId()
                                                                      startTime:SpanOptions().startTime 
                                                                     firstClass:BSGTriStateNo
                                                            samplingProbability:1.0
                                                            attributeCountLimit:128
                                                                 metricsOptions:metricsOptions
                                                         conditionsToEndOnClose:@[]
                                                                   onSpanEndSet:^(BugsnagPerformanceSpan * _Nonnull) {}
                                                                   onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}
                                                                  onSpanBlocked:^BugsnagPerformanceSpanCondition * _Nullable (BugsnagPerformanceSpan * _Nonnull, NSTimeInterval) { return nil; }
                                                                   onSpanCancelled:^(BugsnagPerformanceSpan * _Nonnull) {}];
    BugsnagPerformanceSpanOptions *objcOptions = [BugsnagPerformanceSpanOptions new];
    objcOptions.startTime = [NSDate dateWithTimeIntervalSinceReferenceDate:1.0];
    objcOptions.parentContext = span;
    objcOptions.makeCurrentContext = true;
    objcOptions.firstClass = BSGTriStateNo;
    
    SpanOptions cOptions(objcOptions);
    XCTAssertEqual(1.0, cOptions.startTime);
    XCTAssertEqual(span, cOptions.parentContext);
    XCTAssertEqual(true, cOptions.makeCurrentContext);
    XCTAssertEqual(BSGTriStateNo, cOptions.firstClass);
}

@end
