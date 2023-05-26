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
#import "Span.h"
#import "SpanData.h"
#import "SpanOptions.h"
#import "BugsnagPerformanceSpan+Private.h"
#import <memory>

using namespace bugsnag;

@interface SpanOptionsTests : XCTestCase

@end


@implementation SpanOptionsTests

- (void)testUnset {
    BugsnagPerformanceSpanOptions *objcOptions = [BugsnagPerformanceSpanOptions new];
    XCTAssertNil(objcOptions.parentContext);
    XCTAssertNil(objcOptions.startTime);
    XCTAssertTrue(objcOptions.makeCurrentContext);
    XCTAssertEqual(objcOptions.firstClass, BSGFirstClassUnset);
}

- (void)testConversionDefaults {
    BugsnagPerformanceSpanOptions *objcOptions = [BugsnagPerformanceSpanOptions new];
    SpanOptions cOptions(objcOptions);
    XCTAssertNil(cOptions.parentContext);
    XCTAssertTrue(isnan(cOptions.startTime));
    XCTAssertTrue(cOptions.makeCurrentContext);
    XCTAssertEqual(cOptions.firstClass, BSGFirstClassUnset);
}

- (void)testConversion {
    BugsnagPerformanceSpan *span = [[BugsnagPerformanceSpan alloc] initWithSpan:std::make_unique<Span>(@"test",
                                                                                                          IdGenerator::generateTraceId(),
                                                                                                          IdGenerator::generateSpanId(),
                                                                                                          IdGenerator::generateSpanId(),
                                                                                                          SpanOptions().startTime,
                                                                                                          BSGFirstClassNo,
                                                                                                          ^void(std::shared_ptr<SpanData> spanData) {
        NSLog(@"%llu", spanData->spanId);
    })];
    BugsnagPerformanceSpanOptions *objcOptions = [BugsnagPerformanceSpanOptions new];
    objcOptions.startTime = [NSDate dateWithTimeIntervalSinceReferenceDate:1.0];
    objcOptions.parentContext = span;
    objcOptions.makeCurrentContext = true;
    objcOptions.firstClass = BSGFirstClassNo;
    
    SpanOptions cOptions(objcOptions);
    XCTAssertEqual(1.0, cOptions.startTime);
    XCTAssertEqual(span, cOptions.parentContext);
    XCTAssertEqual(true, cOptions.makeCurrentContext);
    XCTAssertEqual(BSGFirstClassNo, cOptions.firstClass);
}

@end
