//
//  OtlpTraceExporterTests.mm
//  
//
//  Created by Nick Dowell on 27/09/2022.
//

#import <XCTest/XCTest.h>

#import "../../Sources/BugsnagPerformance/OtlpTraceExporter.h"

#define XCTAssertIsKindOfClass(EXPR, CLASS) ({ \
    id obj = EXPR; \
    XCTAssert([obj isKindOfClass:CLASS], @"Expected %@ but got %@", CLASS, obj); \
})

using namespace bugsnag;

@interface OtlpTraceExporterTests : XCTestCase

@end

@implementation OtlpTraceExporterTests

- (void)testEncodeBoolValue {
    XCTAssertEqualObjects(OtlpTraceExporter::encode(@{@"key": @NO}), (@[@{@"key": @"key", @"value": @{@"boolValue": @NO}}]));
    XCTAssertEqualObjects(OtlpTraceExporter::encode(@{@"key": @YES}), (@[@{@"key": @"key", @"value": @{@"boolValue": @YES}}]));
}

- (void)testEncodeDoubleValue {
    XCTAssertEqualObjects(OtlpTraceExporter::encode(@{@"key": @1.23}), (@[@{@"key": @"key", @"value": @{@"doubleValue": @1.23}}]));
    XCTAssertEqualObjects(OtlpTraceExporter::encode(@{@"key": @1.f}), (@[@{@"key": @"key", @"value": @{@"doubleValue": @1.f}}]));
}

- (void)testEncodeInt32Value {
    XCTAssertEqualObjects(OtlpTraceExporter::encode(@{@"key": @0}), (@[@{@"key": @"key", @"value": @{@"intValue": @0}}]));
    XCTAssertEqualObjects(OtlpTraceExporter::encode(@{@"key": @1}), (@[@{@"key": @"key", @"value": @{@"intValue": @1}}]));
    XCTAssertEqualObjects(OtlpTraceExporter::encode(@{@"key": @2147483647}), (@[@{@"key": @"key", @"value": @{@"intValue": @2147483647}}]));
}

- (void)testEncodeInt64Value {
    XCTAssertEqualObjects(OtlpTraceExporter::encode(@{@"key": @18446744073709551615ULL}), (@[@{@"key": @"key", @"value": @{@"intValue": @"18446744073709551615"}}]));
}

- (void)testEncodeStringValue {
    XCTAssertEqualObjects(OtlpTraceExporter::encode(@{@"key": @"Hello"}), (@[@{@"key": @"key", @"value": @{@"stringValue": @"Hello"}}]));
}

- (void)testEncodeRequest {
    auto json = OtlpTraceExporter::encode(Span(@"Name", 0, ^(const Span &span) {}), @{});
    
    XCTAssertIsKindOfClass(json[@"resourceSpans"], [NSArray class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0], [NSDictionary class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"resource"], [NSDictionary class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"resource"][@"attributes"], [NSArray class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"scopeSpans"], [NSArray class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"scopeSpans"][0], [NSDictionary class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"scopeSpans"][0][@"spans"], [NSArray class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"scopeSpans"][0][@"spans"][0][@"spanId"], [NSString class]);
}

- (void)testEncodeSpan {
    auto startTime = [NSDate dateWithTimeIntervalSince1970:1664352000].timeIntervalSinceReferenceDate;
    
    Span span(@"My span", startTime, ^(const Span &span) {});
    span.end(startTime + 15);
    
    auto json = OtlpTraceExporter::encode(span);
    
    NSString *traceId = json[@"traceId"];
    XCTAssert([traceId isKindOfClass:[NSString class]]);
    XCTAssertEqual(traceId.length, 32, @"traceId should be a hex encoded 16-byte array");
    
    NSString *spanId = json[@"spanId"];
    XCTAssert([spanId isKindOfClass:[NSString class]]);
    XCTAssertEqual(spanId.length, 16, @"spanId should be a hex encoded 8-byte array");
    
    XCTAssertEqualObjects(json[@"name"], @"My span");
    
    XCTAssertEqualObjects(json[@"kind"], @"SPAN_KIND_INTERNAL");
    
    XCTAssertEqualObjects(json[@"startTimeUnixNano"], @"1664352000000000000");
    XCTAssertEqualObjects(json[@"endTimeUnixNano"], @"1664352015000000000");
}

@end
