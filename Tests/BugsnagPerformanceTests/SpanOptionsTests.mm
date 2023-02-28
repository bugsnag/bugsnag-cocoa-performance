//
//  SpanOptionsTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 16.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BugsnagPerformance/BugsnagPerformanceSpan.h>
#import "BugsnagPerformanceSpanOptions+Private.h"
#import "SpanOptions.h"

using namespace bugsnag;

@interface SpanOptionsTests : XCTestCase

@end

@interface MockContext: NSObject<BugsnagPerformanceSpanContext>

@property(nonatomic,readonly) TraceId traceId;
@property(nonatomic,readonly) SpanId spanId;
@property(nonatomic,readonly) bool isValid;

@end

@implementation MockContext

@end


@implementation SpanOptionsTests

- (void)testUnset {
    BugsnagPerformanceSpanOptions *objcOptions = [BugsnagPerformanceSpanOptions new];
    XCTAssertNil(objcOptions.parentContext);
    XCTAssertNil(objcOptions.startTime);
    XCTAssertTrue(objcOptions.makeContextCurrent);
    XCTAssertFalse(objcOptions.isFirstClass);
    XCTAssertFalse(objcOptions.wasFirstClassSet);
}

- (void)testConversionDefaults {
    BugsnagPerformanceSpanOptions *objcOptions = [BugsnagPerformanceSpanOptions new];
    SpanOptions cOptions = SpanOptionsForCustom(objcOptions);
    XCTAssertNil(cOptions.parentContext);
    XCTAssertTrue(abs(cOptions.startTime - CFAbsoluteTimeGetCurrent()) < 1);
    XCTAssertTrue(cOptions.makeContextCurrent);
    XCTAssertFalse(objcOptions.isFirstClass);
    XCTAssertFalse(objcOptions.wasFirstClassSet);
}

- (void)testConversion {
    id<BugsnagPerformanceSpanContext> context = [MockContext new];
    BugsnagPerformanceSpanOptions *objcOptions = [BugsnagPerformanceSpanOptions new];
    objcOptions.startTime = [NSDate dateWithTimeIntervalSinceReferenceDate:1.0];
    objcOptions.parentContext = context;
    objcOptions.makeContextCurrent = true;
    objcOptions.isFirstClass = false;

    SpanOptions cOptions = SpanOptionsForCustom(objcOptions);
    XCTAssertEqual(1.0, cOptions.startTime);
    XCTAssertEqual(context, cOptions.parentContext);
    XCTAssertEqual(true, cOptions.makeContextCurrent);
    XCTAssertFalse(objcOptions.isFirstClass);
    XCTAssertTrue(objcOptions.wasFirstClassSet);


    objcOptions = [BugsnagPerformanceSpanOptions new];
    objcOptions.startTime = [NSDate dateWithTimeIntervalSinceReferenceDate:1.0];
    objcOptions.parentContext = context;
    objcOptions.makeContextCurrent = true;
    objcOptions.isFirstClass = true;

    cOptions = SpanOptionsForCustom(objcOptions);
    XCTAssertEqual(1.0, cOptions.startTime);
    XCTAssertEqual(context, cOptions.parentContext);
    XCTAssertEqual(true, cOptions.makeContextCurrent);
    XCTAssertTrue(objcOptions.isFirstClass);
    XCTAssertTrue(objcOptions.wasFirstClassSet);


    objcOptions = [BugsnagPerformanceSpanOptions new];
    objcOptions.startTime = [NSDate dateWithTimeIntervalSinceReferenceDate:1.0];
    objcOptions.parentContext = context;
    objcOptions.makeContextCurrent = true;

    cOptions = SpanOptionsForCustom(objcOptions);
    XCTAssertEqual(1.0, cOptions.startTime);
    XCTAssertEqual(context, cOptions.parentContext);
    XCTAssertEqual(true, cOptions.makeContextCurrent);
    XCTAssertFalse(objcOptions.isFirstClass);
    XCTAssertFalse(objcOptions.wasFirstClassSet);
}

@end
