//
//  SpanTests.m
//  BugsnagPerformance
//
//  Created by Nick Dowell on 26/09/2022.
//

#import <XCTest/XCTest.h>

#import "../../Sources/BugsnagPerformance/Span.h"

#import <memory>

@interface SpanTests : XCTestCase

@end

@implementation SpanTests

- (void)testEncode {
    auto span = std::make_shared<Span>(@"My span", CFAbsoluteTimeGetCurrent(), ^(const Span &span) {});
    span->end();
    auto json = span->encode();
    
    NSString *traceId = json[@"traceId"];
    XCTAssert([traceId isKindOfClass:[NSString class]]);
    XCTAssertEqual(traceId.length, 32, @"traceId should be a hex encoded 16-byte array");
    
    NSString *spanId = json[@"spanId"];
    XCTAssert([spanId isKindOfClass:[NSString class]]);
    XCTAssertEqual(spanId.length, 16, @"spanId should be a hex encoded 8-byte array");
    
    XCTAssertEqualObjects(json[@"name"], @"My span");
    
    XCTAssertEqualObjects(json[@"kind"], @"SPAN_KIND_INTERNAL");
    
    XCTAssert([json[@"startTimeUnixNano"] isKindOfClass:[NSString class]]);
    XCTAssert([json[@"endTimeUnixNano"] isKindOfClass:[NSString class]]);
}

@end
