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

using namespace bugsnag;

@interface SpanOptionsTests : XCTestCase

@end

@interface MockContext: NSObject<BugsnagPerformanceSpanContext>

@property(nonatomic,readonly) TraceId traceId;
@property(nonatomic,readonly) SpanId spanId;

@end

@implementation MockContext

@synthesize isValid;

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
    XCTAssertTrue(cOptions.makeContextCurrent);
    XCTAssertEqual(cOptions.firstClass, BSGFirstClassUnset);
}

- (void)testConversion {
    id<BugsnagPerformanceSpanContext> context = [MockContext new];
    BugsnagPerformanceSpanOptions *objcOptions = [BugsnagPerformanceSpanOptions new];
    objcOptions.startTime = [NSDate dateWithTimeIntervalSinceReferenceDate:1.0];
    objcOptions.parentContext = context;
    objcOptions.makeCurrentContext = true;
    objcOptions.firstClass = BSGFirstClassNo;

    SpanOptions cOptions(objcOptions);
    XCTAssertEqual(1.0, cOptions.startTime);
    XCTAssertEqual(context, cOptions.parentContext);
    XCTAssertEqual(true, cOptions.makeContextCurrent);
    XCTAssertEqual(BSGFirstClassNo, cOptions.firstClass);
}

@end
