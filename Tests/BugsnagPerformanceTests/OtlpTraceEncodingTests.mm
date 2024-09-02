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

static id findAttributeNamed(NSDictionary *span, NSString *name) {
    for (NSDictionary *attribute in span[@"attributes"]) {
        if ([attribute[@"key"] isEqual:name]) {
            id value = attribute[@"value"][@"stringValue"];
            if (value != nil) {
                return value;
            }
            value = attribute[@"value"][@"intValue"];
            if (value != nil) {
                return [NSNumber numberWithLong:[value longValue]];
            }
            value = attribute[@"value"][@"boolValue"];
            if (value != nil) {
                return value;
            }
        }
    }
    return nil;
}

@implementation OtlpTraceEncodingTests

- (void)testEncodeBoolValue {
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @NO}), (@[@{@"key": @"key", @"value": @{@"boolValue": @NO}}]));
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @YES}), (@[@{@"key": @"key", @"value": @{@"boolValue": @YES}}]));
}

- (void)testEncodeDoubleValue {
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @1.23}), (@[@{@"key": @"key", @"value": @{@"doubleValue": @1.23}}]));
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @1.f}), (@[@{@"key": @"key", @"value": @{@"doubleValue": @1.0}}]));
}

- (void)testEncodeInt32Value {
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @0}), (@[@{@"key": @"key", @"value": @{@"intValue": @"0"}}]));
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @1}), (@[@{@"key": @"key", @"value": @{@"intValue": @"1"}}]));
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @2147483647}), (@[@{@"key": @"key", @"value": @{@"intValue": @"2147483647"}}]));
}

- (void)testEncodeInt64Value {
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @18446744073709551615ULL}), (@[@{@"key": @"key", @"value": @{@"intValue": @"18446744073709551615"}}]));
}

- (void)testEncodeStringValue {
    XCTAssertEqualObjects(OtlpTraceEncoding::encode(@{@"key": @"Hello"}), (@[@{@"key": @"key", @"value": @{@"stringValue": @"Hello"}}]));
}

- (void)testEncodeRequestFirstClassYes {
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@""
                                                          traceId:tid
                                                           spanId:1
                                                         parentId:0
                                                        startTime:CFAbsoluteTimeGetCurrent()
                                                       firstClass:BSGFirstClassYes
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    auto json = OtlpTraceEncoding::encode(spans, @{});
    
    XCTAssertIsKindOfClass(json[@"resourceSpans"], [NSArray class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0], [NSDictionary class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"resource"], [NSDictionary class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"resource"][@"attributes"], [NSArray class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"scopeSpans"], [NSArray class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"scopeSpans"][0], [NSDictionary class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"scopeSpans"][0][@"spans"], [NSArray class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"scopeSpans"][0][@"spans"][0][@"spanId"], [NSString class]);

    NSDictionary *span = json[@"resourceSpans"][0][@"scopeSpans"][0][@"spans"][0];
    XCTAssertNotNil(span);
    XCTAssertEqualObjects(findAttributeNamed(span, @"bugsnag.span.first_class"), @YES);
}

- (void)testEncodeRequestFirstClassNo {
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@""
                                                          traceId:tid
                                                           spanId:1
                                                         parentId:0
                                                        startTime:CFAbsoluteTimeGetCurrent()
                                                       firstClass:BSGFirstClassNo
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    auto json = OtlpTraceEncoding::encode(spans, @{});
    
    XCTAssertIsKindOfClass(json[@"resourceSpans"], [NSArray class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0], [NSDictionary class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"resource"], [NSDictionary class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"resource"][@"attributes"], [NSArray class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"scopeSpans"], [NSArray class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"scopeSpans"][0], [NSDictionary class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"scopeSpans"][0][@"spans"], [NSArray class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"scopeSpans"][0][@"spans"][0][@"spanId"], [NSString class]);

    NSDictionary *span = json[@"resourceSpans"][0][@"scopeSpans"][0][@"spans"][0];
    XCTAssertNotNil(span);
    XCTAssertEqualObjects(findAttributeNamed(span, @"bugsnag.span.first_class"), @NO);
}

- (void)testEncodeRequestFirstClassUnset {
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@""
                                                          traceId:tid
                                                           spanId:1
                                                         parentId:0
                                                        startTime:CFAbsoluteTimeGetCurrent()
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    auto json = OtlpTraceEncoding::encode(spans, @{});
    
    XCTAssertIsKindOfClass(json[@"resourceSpans"], [NSArray class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0], [NSDictionary class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"resource"], [NSDictionary class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"resource"][@"attributes"], [NSArray class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"scopeSpans"], [NSArray class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"scopeSpans"][0], [NSDictionary class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"scopeSpans"][0][@"spans"], [NSArray class]);
    XCTAssertIsKindOfClass(json[@"resourceSpans"][0][@"scopeSpans"][0][@"spans"][0][@"spanId"], [NSString class]);

    NSDictionary *span = json[@"resourceSpans"][0][@"scopeSpans"][0][@"spans"][0];
    XCTAssertNotNil(span);
    XCTAssertNil(findAttributeNamed(span, @"bugsnag.span.first_class"));
}

- (void)testEncodeSpan {
    CFAbsoluteTime startTime = [NSDate dateWithTimeIntervalSince1970:1664352000].timeIntervalSinceReferenceDate;
    
    TraceId tid = {
        .hi=0xfedcba9876543210,
        .lo=0x0123456789abcdef
    };
    BugsnagPerformanceSpan *span = [[BugsnagPerformanceSpan alloc] initWithName:@"My span"
                                                                        traceId:tid
                                                                         spanId:0xface
                                                                       parentId:0
                                                                      startTime:startTime
                                                                     firstClass:BSGFirstClassUnset
                                                                    onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}];
    [span setEndAbsTime:startTime + 15];
    
    auto json = OtlpTraceEncoding::encode(span);
    
    NSString *traceId = json[@"traceId"];
    XCTAssert([traceId isKindOfClass:[NSString class]]);
    XCTAssertEqualObjects(traceId, @"fedcba98765432100123456789abcdef");
    
    NSString *spanId = json[@"spanId"];
    XCTAssert([spanId isKindOfClass:[NSString class]]);
    XCTAssertEqualObjects(spanId, @"000000000000face");

    XCTAssertNil(json[@"parentSpanId"]);

    XCTAssertEqualObjects(json[@"name"], @"My span");
    
    XCTAssertEqualObjects(json[@"kind"], @1);
    
    XCTAssertEqualObjects(json[@"startTimeUnixNano"], @"1664352000000000000");
    XCTAssertEqualObjects(json[@"endTimeUnixNano"], @"1664352015000000000");
}

- (void)testEncodeSpanWithParent {
    CFAbsoluteTime startTime = [NSDate dateWithTimeIntervalSince1970:1664352000].timeIntervalSinceReferenceDate;
    
    TraceId tid = {
        .hi=0xfedcba9876543210,
        .lo=0x0123456789abcdef
    };
    BugsnagPerformanceSpan *span = [[BugsnagPerformanceSpan alloc] initWithName:@"My span"
                                                                        traceId:tid
                                                                         spanId:0xface
                                                                       parentId:0xcafe
                                                                      startTime:startTime
                                                                     firstClass:BSGFirstClassUnset
                                                                    onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}];
    [span setEndAbsTime:startTime + 15];
    
    auto json = OtlpTraceEncoding::encode(span);
    
    NSString *traceId = json[@"traceId"];
    XCTAssert([traceId isKindOfClass:[NSString class]]);
    XCTAssertEqualObjects(traceId, @"fedcba98765432100123456789abcdef");
    
    NSString *spanId = json[@"spanId"];
    XCTAssert([spanId isKindOfClass:[NSString class]]);
    XCTAssertEqualObjects(spanId, @"000000000000face");

    NSString *parentId = json[@"parentSpanId"];
    XCTAssert([parentId isKindOfClass:[NSString class]]);
    XCTAssertEqualObjects(parentId, @"000000000000cafe");

    XCTAssertEqualObjects(json[@"name"], @"My span");
    
    XCTAssertEqualObjects(json[@"kind"], @(SPAN_KIND_INTERNAL));
    
    XCTAssertEqualObjects(json[@"startTimeUnixNano"], @"1664352000000000000");
    XCTAssertEqualObjects(json[@"endTimeUnixNano"], @"1664352015000000000");
}

- (void)testBuildPValueRequestPackage {
    auto package = OtlpTraceEncoding::buildPValueRequestPackage();
    XCTAssertEqual(0U, package->timestamp);
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
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test"
                                                          traceId:tid
                                                           spanId:1
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    auto resourceAttributes = @{};
    auto package = OtlpTraceEncoding::buildUploadPackage(spans, resourceAttributes, true);

    XCTAssertGreaterThan(package->timestamp, 0U);
    XCTAssertNotNil(package->getPayloadForUnitTest());
    XCTAssertNotNil(package->getHeadersForUnitTest());

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"gzip", headers[@"Content-Encoding"]);
    XCTAssertEqualObjects(@"application/json", headers[@"Content-Type"]);
    XCTAssertNotNil(headers[@"Bugsnag-Integrity"]);
}

- (void)testPValueHistogram1 {
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test1"
                                                          traceId:tid
                                                           spanId:1
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans[0] updateSamplingProbability:0.3];

    auto resourceAttributes = @{};
    auto package = OtlpTraceEncoding::buildUploadPackage(spans, resourceAttributes, true);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"0.3:1", headers[@"Bugsnag-Span-Sampling"]);
}

- (void)testPValueHistogram2 {
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test1"
                                                          traceId:tid
                                                           spanId:1
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test2"
                                                          traceId:tid
                                                           spanId:2
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans[0] updateSamplingProbability:0.3];
    [spans[1] updateSamplingProbability:0.1];

    auto resourceAttributes = @{};
    auto package = OtlpTraceEncoding::buildUploadPackage(spans, resourceAttributes, true);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"0.1:1;0.3:1", headers[@"Bugsnag-Span-Sampling"]);
}

- (void)testPValueHistogram2Same {
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test1"
                                                          traceId:tid
                                                           spanId:1
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test2"
                                                          traceId:tid
                                                           spanId:2
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans[0] updateSamplingProbability:0.5];
    [spans[1] updateSamplingProbability:0.5];

    auto resourceAttributes = @{};
    auto package = OtlpTraceEncoding::buildUploadPackage(spans, resourceAttributes, true);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"0.5:2", headers[@"Bugsnag-Span-Sampling"]);
}

- (void)testPValueHistogram5 {
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test1"
                                                          traceId:tid
                                                           spanId:1
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test2"
                                                          traceId:tid
                                                           spanId:2
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test3"
                                                          traceId:tid
                                                           spanId:3
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test4"
                                                          traceId:tid
                                                           spanId:4
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test5"
                                                          traceId:tid
                                                           spanId:5
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans[0] updateSamplingProbability:0.3];
    [spans[1] updateSamplingProbability:0.1];
    [spans[2] updateSamplingProbability:0.3];
    [spans[3] updateSamplingProbability:0.5];
    [spans[4] updateSamplingProbability:0.1];

    auto resourceAttributes = @{};
    auto package = OtlpTraceEncoding::buildUploadPackage(spans, resourceAttributes, true);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"0.1:2;0.3:2;0.5:1", headers[@"Bugsnag-Span-Sampling"]);
}

- (void)testPValueHistogram11 {
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test0"
                                                          traceId:tid
                                                           spanId:1
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test1"
                                                          traceId:tid
                                                           spanId:2
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test2"
                                                          traceId:tid
                                                           spanId:3
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test3"
                                                          traceId:tid
                                                           spanId:4
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test4"
                                                          traceId:tid
                                                           spanId:5
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test5"
                                                          traceId:tid
                                                           spanId:6
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test6"
                                                          traceId:tid
                                                           spanId:7
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test7"
                                                          traceId:tid
                                                           spanId:8
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test8"
                                                          traceId:tid
                                                           spanId:9
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test9"
                                                          traceId:tid
                                                           spanId:10
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test10"
                                                          traceId:tid
                                                           spanId:11
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans[0] updateSamplingProbability:0.0];
    [spans[1] updateSamplingProbability:0.1];
    [spans[2] updateSamplingProbability:0.2];
    [spans[3] updateSamplingProbability:0.3];
    [spans[4] updateSamplingProbability:0.4];
    [spans[5] updateSamplingProbability:0.5];
    [spans[6] updateSamplingProbability:0.6];
    [spans[7] updateSamplingProbability:0.7];
    [spans[8] updateSamplingProbability:0.8];
    [spans[9] updateSamplingProbability:0.9];
    [spans[10] updateSamplingProbability:1];

    auto resourceAttributes = @{};
    auto package = OtlpTraceEncoding::buildUploadPackage(spans, resourceAttributes, true);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"0:1;0.1:1;0.2:1;0.3:1;0.4:1;0.5:1;0.6:1;0.7:1;0.8:1;0.9:1;1:1", headers[@"Bugsnag-Span-Sampling"]);
}

- (void)testPValueWithoutHistogram {
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test1"
                                                          traceId:tid
                                                           spanId:1
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test2"
                                                          traceId:tid
                                                           spanId:2
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test3"
                                                          traceId:tid
                                                           spanId:3
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test4"
                                                          traceId:tid
                                                           spanId:4
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans addObject:[[BugsnagPerformanceSpan alloc] initWithName:@"test5"
                                                          traceId:tid
                                                           spanId:5
                                                         parentId:0
                                                        startTime:0
                                                       firstClass:BSGFirstClassUnset
                                                      onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}]];
    [spans[0] updateSamplingProbability:0.3];
    [spans[1] updateSamplingProbability:0.1];
    [spans[2] updateSamplingProbability:0.3];
    [spans[3] updateSamplingProbability:0.5];
    [spans[4] updateSamplingProbability:0.1];

    auto resourceAttributes = @{};
    auto package = OtlpTraceEncoding::buildUploadPackage(spans, resourceAttributes, false);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertNil(headers[@"Bugsnag-Span-Sampling"]);
}

@end
