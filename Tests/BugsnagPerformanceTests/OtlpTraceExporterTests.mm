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

- (void)testEncodeIntValue {
    XCTAssertEqualObjects(OtlpTraceExporter::encode(@{@"key": @0}), (@[@{@"key": @"key", @"value": @{@"intValue": @0}}]));
    XCTAssertEqualObjects(OtlpTraceExporter::encode(@{@"key": @ULONG_MAX}), (@[@{@"key": @"key", @"value": @{@"intValue": @ULONG_MAX}}]));
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
    Span span(@"My span", CFAbsoluteTimeGetCurrent(), ^(const Span &span) {});
    span.end();
    
    auto json = OtlpTraceExporter::encode(span);
    
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
