//
//  OtlpTraceEncodingTests.mm
//  
//
//  Created by Nick Dowell on 27/09/2022.
//

#import <XCTest/XCTest.h>

#import "../../Sources/BugsnagPerformance/Private/OtlpTraceEncoding.h"

#define XCTAssertIsKindOfClass(EXPR, CLASS) ({ \
    id obj = EXPR; \
    XCTAssert([obj isKindOfClass:CLASS], @"Expected %@ but got %@", CLASS, obj); \
})

using namespace bugsnag;

@interface OtlpTraceEncodingTests : XCTestCase

@end

@implementation OtlpTraceEncodingTests

- (void)testEncodeBoolValue {
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @NO}), (@[@{@"key": @"key", @"value": @{@"boolValue": @NO}}]));
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @YES}), (@[@{@"key": @"key", @"value": @{@"boolValue": @YES}}]));
}

- (void)testEncodeDoubleValue {
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @1.23}), (@[@{@"key": @"key", @"value": @{@"doubleValue": @1.23}}]));
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @1.f}), (@[@{@"key": @"key", @"value": @{@"doubleValue": @1.f}}]));
}

- (void)testEncodeInt32Value {
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @0}), (@[@{@"key": @"key", @"value": @{@"intValue": @0}}]));
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @1}), (@[@{@"key": @"key", @"value": @{@"intValue": @1}}]));
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @2147483647}), (@[@{@"key": @"key", @"value": @{@"intValue": @2147483647}}]));
}

- (void)testEncodeInt64Value {
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @18446744073709551615ULL}), (@[@{@"key": @"key", @"value": @{@"intValue": @"18446744073709551615"}}]));
}

- (void)testEncodeStringValue {
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @"Hello"}), (@[@{@"key": @"key", @"value": @{@"stringValue": @"Hello"}}]));
}

- (void)testEncodeRequest {
    std::vector<std::unique_ptr<SpanData>> spans;
    spans.push_back(std::make_unique<SpanData>(@"", CFAbsoluteTimeGetCurrent()));
    auto json = OtlpTraceEncoding::encode(spans, @{});
    
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
    CFAbsoluteTime startTime = [NSDate dateWithTimeIntervalSince1970:1664352000].timeIntervalSinceReferenceDate;
    
    SpanData span(@"My span", startTime);
    span.endTime = startTime + 15;
    
    auto json = OtlpTraceEncoding::encode(span);
    
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

- (void)testBuildPValueRequestPackage {
    auto package = OtlpTraceEncoding::buildPValueRequestPackage();
    XCTAssertEqual(0, package->timestamp);
    NSError *error = nil;
    NSDictionary *deserialized = [NSJSONSerialization JSONObjectWithData:(NSData * _Nonnull)package->getPayloadForUnitTest()
                                                                 options:0
                                                                   error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(@{@"resourceSpans": @[]}, deserialized);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"application/json", headers[@"Content-Type"]);
    XCTAssertNotNil(headers[@"Bugsnag-Integrity"]);
}

- (void)testBuildUploadPackage {
    std::vector<std::unique_ptr<SpanData>> spans;
    spans.push_back(std::make_unique<SpanData>(@"test", 0));
    auto resourceAttributes = @{};
    auto package = OtlpTraceEncoding::buildUploadPackage(spans, resourceAttributes);

    XCTAssertGreaterThan(package->timestamp, 0);
    XCTAssertNotNil(package->getPayloadForUnitTest());
    XCTAssertNotNil(package->getHeadersForUnitTest());

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"gzip", headers[@"Content-Encoding"]);
    XCTAssertEqualObjects(@"application/json", headers[@"Content-Type"]);
    XCTAssertNotNil(headers[@"Bugsnag-Integrity"]);
}

- (void)testPValueHistogram1 {
    std::vector<std::unique_ptr<SpanData>> spans;
    spans.push_back(std::make_unique<SpanData>(@"test1", 0));
    spans[0]->updateSamplingProbability(0.3);

    auto resourceAttributes = @{};
    auto package = OtlpTraceEncoding::buildUploadPackage(spans, resourceAttributes);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"0.3:1", headers[@"Bugsnag-Span-Sampling"]);
}

- (void)testPValueHistogram2 {
    std::vector<std::unique_ptr<SpanData>> spans;
    spans.push_back(std::make_unique<SpanData>(@"test1", 0));
    spans.push_back(std::make_unique<SpanData>(@"test2", 0));
    spans[0]->updateSamplingProbability(0.3);
    spans[1]->updateSamplingProbability(0.1);

    auto resourceAttributes = @{};
    auto package = OtlpTraceEncoding::buildUploadPackage(spans, resourceAttributes);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"0.1:1;0.3:1", headers[@"Bugsnag-Span-Sampling"]);
}

- (void)testPValueHistogram2Same {
    std::vector<std::unique_ptr<SpanData>> spans;
    spans.push_back(std::make_unique<SpanData>(@"test1", 0));
    spans.push_back(std::make_unique<SpanData>(@"test2", 0));
    spans[0]->updateSamplingProbability(0.5);
    spans[1]->updateSamplingProbability(0.5);

    auto resourceAttributes = @{};
    auto package = OtlpTraceEncoding::buildUploadPackage(spans, resourceAttributes);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"0.5:2", headers[@"Bugsnag-Span-Sampling"]);
}

- (void)testPValueHistogram5 {
    std::vector<std::unique_ptr<SpanData>> spans;
    spans.push_back(std::make_unique<SpanData>(@"test1", 0));
    spans.push_back(std::make_unique<SpanData>(@"test2", 0));
    spans.push_back(std::make_unique<SpanData>(@"test3", 0));
    spans.push_back(std::make_unique<SpanData>(@"test4", 0));
    spans.push_back(std::make_unique<SpanData>(@"test5", 0));
    spans[0]->updateSamplingProbability(0.3);
    spans[1]->updateSamplingProbability(0.1);
    spans[2]->updateSamplingProbability(0.3);
    spans[3]->updateSamplingProbability(0.5);
    spans[4]->updateSamplingProbability(0.1);

    auto resourceAttributes = @{};
    auto package = OtlpTraceEncoding::buildUploadPackage(spans, resourceAttributes);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"0.1:2;0.3:2;0.5:1", headers[@"Bugsnag-Span-Sampling"]);
}

- (void)testPValueHistogram11 {
    std::vector<std::unique_ptr<SpanData>> spans;
    spans.push_back(std::make_unique<SpanData>(@"test0", 0));
    spans.push_back(std::make_unique<SpanData>(@"test1", 0));
    spans.push_back(std::make_unique<SpanData>(@"test2", 0));
    spans.push_back(std::make_unique<SpanData>(@"test3", 0));
    spans.push_back(std::make_unique<SpanData>(@"test4", 0));
    spans.push_back(std::make_unique<SpanData>(@"test5", 0));
    spans.push_back(std::make_unique<SpanData>(@"test6", 0));
    spans.push_back(std::make_unique<SpanData>(@"test7", 0));
    spans.push_back(std::make_unique<SpanData>(@"test8", 0));
    spans.push_back(std::make_unique<SpanData>(@"test9", 0));
    spans.push_back(std::make_unique<SpanData>(@"test10", 0));
    spans[0]->updateSamplingProbability(0.0);
    spans[1]->updateSamplingProbability(0.1);
    spans[2]->updateSamplingProbability(0.2);
    spans[3]->updateSamplingProbability(0.3);
    spans[4]->updateSamplingProbability(0.4);
    spans[5]->updateSamplingProbability(0.5);
    spans[6]->updateSamplingProbability(0.6);
    spans[7]->updateSamplingProbability(0.7);
    spans[8]->updateSamplingProbability(0.8);
    spans[9]->updateSamplingProbability(0.9);
    spans[10]->updateSamplingProbability(1);

    auto resourceAttributes = @{};
    auto package = OtlpTraceEncoding::buildUploadPackage(spans, resourceAttributes);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"0:1;0.1:1;0.2:1;0.3:1;0.4:1;0.5:1;0.6:1;0.7:1;0.8:1;0.9:1;1:1", headers[@"Bugsnag-Span-Sampling"]);
}

@end
