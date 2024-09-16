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

- (std::shared_ptr<OtlpTraceEncoding>)newEncoderWithConfig:(BugsnagPerformanceConfiguration *)config {
    BSGEarlyConfiguration *earlyConfig = [[BSGEarlyConfiguration alloc] initWithBundleDictionary:@{}];
    auto encoder = std::make_shared<OtlpTraceEncoding>();
    encoder->earlyConfigure(earlyConfig);
    encoder->earlySetup();
    encoder->configure(config);
    encoder->preStartSetup();
    encoder->start();
    return encoder;
}

- (std::shared_ptr<OtlpTraceEncoding>)newEncoder {
    return [self newEncoderWithConfig:[[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"DUMMY_API_KEY"]];
}

- (void)testEncodeBoolValue {
    auto encoder = [self newEncoder];
    XCTAssertEqualObjects(encoder->encode(@{@"key": @NO}), (@[@{@"key": @"key", @"value": @{@"boolValue": @NO}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"key": @YES}), (@[@{@"key": @"key", @"value": @{@"boolValue": @YES}}]));
}

- (void)testEncodeDoubleValue {
    auto encoder = [self newEncoder];
    XCTAssertEqualObjects(encoder->encode(@{@"key": @1.23}), (@[@{@"key": @"key", @"value": @{@"doubleValue": @1.23}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"key": @1.f}), (@[@{@"key": @"key", @"value": @{@"doubleValue": @1.0}}]));
}

- (void)testEncodeInt32Value {
    auto encoder = [self newEncoder];
    XCTAssertEqualObjects(encoder->encode(@{@"key": @0}), (@[@{@"key": @"key", @"value": @{@"intValue": @"0"}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"key": @1}), (@[@{@"key": @"key", @"value": @{@"intValue": @"1"}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"key": @2147483647}), (@[@{@"key": @"key", @"value": @{@"intValue": @"2147483647"}}]));
}

- (void)testEncodeInt64Value {
    auto encoder = [self newEncoder];
    XCTAssertEqualObjects(encoder->encode(@{@"key": @18446744073709551615ULL}), (@[@{@"key": @"key", @"value": @{@"intValue": @"18446744073709551615"}}]));
}

- (void)testEncodeStringValue {
    // Default configuration
    BugsnagPerformanceConfiguration *config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"XYZ"];
    auto encoder = [self newEncoderWithConfig:config];
    XCTAssertEqualObjects(encoder->encode(@{@"key": @"Hello"}), (@[@{@"key": @"key", @"value": @{@"stringValue": @"Hello"}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"key": @""}),
                          (@[@{@"key": @"key", @"value": @{@"stringValue": @""}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"key": @"123456789012345678901234567890"}),
                          (@[@{@"key": @"key", @"value": @{@"stringValue": @"123456789012345678901234567890"}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"key": @"1234567890123456789012345678901"}),
                          (@[@{@"key": @"key", @"value": @{@"stringValue": @"1234567890123456789012345678901"}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"key": @"1234567890123456789012345678901234567890"}),
                          (@[@{@"key": @"key", @"value": @{@"stringValue": @"1234567890123456789012345678901234567890"}}]));

    // Low limit
    config.attributeStringValueLimit = 30;
    encoder = [self newEncoderWithConfig:config];
    XCTAssertEqualObjects(encoder->encode(@{@"key": @""}),
                          (@[@{@"key": @"key", @"value": @{@"stringValue": @""}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"key": @"123456789012345678901234567890"}),
                          (@[@{@"key": @"key", @"value": @{@"stringValue": @"123456789012345678901234567890"}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"key": @"1234567890123456789012345678901"}),
                          (@[@{@"key": @"key", @"value": @{@"stringValue": @"123456789012345678901234567890*** 1 CHARS TRUNCATED"}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"key": @"1234567890123456789012345678901234567890"}),
                          (@[@{@"key": @"key", @"value": @{@"stringValue": @"123456789012345678901234567890*** 10 CHARS TRUNCATED"}}]));

    // Ridiculously low limit
    config.attributeStringValueLimit = 1;
    encoder = [self newEncoderWithConfig:config];
    XCTAssertEqualObjects(encoder->encode(@{@"key": @""}),
                          (@[@{@"key": @"key", @"value": @{@"stringValue": @""}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"key": @"1"}),
                          (@[@{@"key": @"key", @"value": @{@"stringValue": @"1"}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"key": @"1234567890123456789012345678901"}),
                          (@[@{@"key": @"key", @"value": @{@"stringValue": @"1*** 30 CHARS TRUNCATED"}}]));

    // Zero limit, which resets to default
    config.attributeStringValueLimit = 0;
    encoder = [self newEncoderWithConfig:config];
    XCTAssertEqualObjects(encoder->encode(@{@"key": @""}),
                          (@[@{@"key": @"key", @"value": @{@"stringValue": @""}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"key": @"1"}),
                          (@[@{@"key": @"key", @"value": @{@"stringValue": @"1"}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"key": @"1234567890123456789012345678901"}),
                          (@[@{@"key": @"key", @"value": @{@"stringValue": @"1234567890123456789012345678901"}}]));
}

- (void)testEncodeArrayValue {
    // Default configuration
    BugsnagPerformanceConfiguration *config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"XYZ"];

    auto encoder = [self newEncoderWithConfig:config];
    XCTAssertEqualObjects(encoder->encode(@{@"mykey": @[@1,@2,@3]}), (@[@{@"key": @"mykey", @"value": @{@"arrayValue":
                                            @{@"values":
                                                  @[
                                                      @{@"intValue": @"1"},
                                                      @{@"intValue": @"2"},
                                                      @{@"intValue": @"3"}]}}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"mykey": @[@1.5,@2.5,@3.5]}), (@[@{@"key": @"mykey", @"value": @{@"arrayValue":
                                            @{@"values":
                                                  @[
                                                      @{@"doubleValue": @1.5},
                                                      @{@"doubleValue": @2.5},
                                                      @{@"doubleValue": @3.5}]}}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"mykey": @[@"a",@"b",@"c"]}), (@[@{@"key": @"mykey", @"value": @{@"arrayValue":
                                            @{@"values":
                                                  @[
                                                      @{@"stringValue": @"a"},
                                                      @{@"stringValue": @"b"},
                                                      @{@"stringValue": @"c"}]}}}]));

    config.attributeArrayLengthLimit = 2;
    encoder = [self newEncoderWithConfig:config];
    XCTAssertEqualObjects(encoder->encode(@{@"mykey": @[@1,@2]}), (@[@{@"key": @"mykey", @"value": @{@"arrayValue":
                                            @{@"values":
                                                  @[
                                                      @{@"intValue": @"1"},
                                                      @{@"intValue": @"2"}]}}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"mykey": @[@1.5,@2.5]}), (@[@{@"key": @"mykey", @"value": @{@"arrayValue":
                                            @{@"values":
                                                  @[
                                                      @{@"doubleValue": @1.5},
                                                      @{@"doubleValue": @2.5}]}}}]));
    XCTAssertEqualObjects(encoder->encode(@{@"mykey": @[@"a",@"b"]}), (@[@{@"key": @"mykey", @"value": @{@"arrayValue":
                                            @{@"values":
                                                  @[
                                                      @{@"stringValue": @"a"},
                                                      @{@"stringValue": @"b"}]}}}]));
}

- (BugsnagPerformanceSpan *)spanWithName:(NSString *)name
                                 traceId:(TraceId) traceId
                                  spanId:(SpanId) spanId
                                parentId:(SpanId) parentId
                               startTime:(CFAbsoluteTime) startAbsTime
                              firstClass:(BSGFirstClass) firstClass {
    return [[BugsnagPerformanceSpan alloc] initWithName:name
                                                traceId:traceId
                                                 spanId:spanId
                                               parentId:parentId
                                              startTime:startAbsTime
                                             firstClass:firstClass
                                    attributeCountLimit:128
                                           onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}];
}

- (void)testEncodeRequestFirstClassYes {
    auto encoder = [self newEncoder];
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[self spanWithName:@""
                                traceId:tid
                                 spanId:1
                               parentId:0
                              startTime:CFAbsoluteTimeGetCurrent()
                             firstClass:BSGFirstClassYes]];
    auto json = encoder->encode(spans, @{});
    
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
    auto encoder = [self newEncoder];
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[self spanWithName:@""
                                traceId:tid
                                 spanId:1
                               parentId:0
                              startTime:CFAbsoluteTimeGetCurrent()
                             firstClass:BSGFirstClassNo]];
    auto json = encoder->encode(spans, @{});
    
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
    auto encoder = [self newEncoder];
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[self spanWithName:@""
                                traceId:tid
                                 spanId:1
                               parentId:0
                              startTime:CFAbsoluteTimeGetCurrent()
                             firstClass:BSGFirstClassUnset]];
    auto json = encoder->encode(spans, @{});
    
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
    auto encoder = [self newEncoder];
    CFAbsoluteTime startTime = [NSDate dateWithTimeIntervalSince1970:1664352000].timeIntervalSinceReferenceDate;
    
    TraceId tid = {
        .hi=0xfedcba9876543210,
        .lo=0x0123456789abcdef
    };
    BugsnagPerformanceSpan *span = [self spanWithName:@"My span"
                                              traceId:tid
                                               spanId:0xface
                                             parentId:0
                                            startTime:startTime
                                           firstClass:BSGFirstClassUnset];
    [span setEndAbsTime:startTime + 15];
    
    auto json = encoder->encode(span);
    
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
    auto encoder = [self newEncoder];
    CFAbsoluteTime startTime = [NSDate dateWithTimeIntervalSince1970:1664352000].timeIntervalSinceReferenceDate;
    
    TraceId tid = {
        .hi=0xfedcba9876543210,
        .lo=0x0123456789abcdef
    };
    BugsnagPerformanceSpan *span = [self spanWithName:@"My span"
                                              traceId:tid
                                               spanId:0xface
                                             parentId:0xcafe
                                            startTime:startTime
                                           firstClass:BSGFirstClassUnset];
    [span setEndAbsTime:startTime + 15];
    
    auto json = encoder->encode(span);
    
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
    auto encoder = [self newEncoder];
    auto package = encoder->buildPValueRequestPackage();
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
    auto encoder = [self newEncoder];
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[self spanWithName:@"test"
                                traceId:tid
                                 spanId:1
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    auto resourceAttributes = @{};
    auto package = encoder->buildUploadPackage(spans, resourceAttributes, true);

    XCTAssertGreaterThan(package->timestamp, 0U);
    XCTAssertNotNil(package->getPayloadForUnitTest());
    XCTAssertNotNil(package->getHeadersForUnitTest());

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"gzip", headers[@"Content-Encoding"]);
    XCTAssertEqualObjects(@"application/json", headers[@"Content-Type"]);
    XCTAssertNotNil(headers[@"Bugsnag-Integrity"]);
}

- (void)testPValueHistogram1 {
    auto encoder = [self newEncoder];
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[self spanWithName:@"test1"
                                traceId:tid
                                 spanId:1
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans[0] updateSamplingProbability:0.3];

    auto resourceAttributes = @{};
    auto package = encoder->buildUploadPackage(spans, resourceAttributes, true);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"0.3:1", headers[@"Bugsnag-Span-Sampling"]);
}

- (void)testPValueHistogram2 {
    auto encoder = [self newEncoder];
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[self spanWithName:@"test1"
                                traceId:tid
                                 spanId:1
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test2"
                                traceId:tid
                                 spanId:2
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans[0] updateSamplingProbability:0.3];
    [spans[1] updateSamplingProbability:0.1];

    auto resourceAttributes = @{};
    auto package = encoder->buildUploadPackage(spans, resourceAttributes, true);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"0.1:1;0.3:1", headers[@"Bugsnag-Span-Sampling"]);
}

- (void)testPValueHistogram2Same {
    auto encoder = [self newEncoder];
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[self spanWithName:@"test1"
                                traceId:tid
                                 spanId:1
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test2"
                                traceId:tid
                                 spanId:2
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans[0] updateSamplingProbability:0.5];
    [spans[1] updateSamplingProbability:0.5];

    auto resourceAttributes = @{};
    auto package = encoder->buildUploadPackage(spans, resourceAttributes, true);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"0.5:2", headers[@"Bugsnag-Span-Sampling"]);
}

- (void)testPValueHistogram5 {
    auto encoder = [self newEncoder];
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[self spanWithName:@"test1"
                                traceId:tid
                                 spanId:1
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test2"
                                traceId:tid
                                 spanId:2
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test3"
                                traceId:tid
                                 spanId:3
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test4"
                                traceId:tid
                                 spanId:4
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test5"
                                traceId:tid
                                 spanId:5
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans[0] updateSamplingProbability:0.3];
    [spans[1] updateSamplingProbability:0.1];
    [spans[2] updateSamplingProbability:0.3];
    [spans[3] updateSamplingProbability:0.5];
    [spans[4] updateSamplingProbability:0.1];

    auto resourceAttributes = @{};
    auto package = encoder->buildUploadPackage(spans, resourceAttributes, true);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"0.1:2;0.3:2;0.5:1", headers[@"Bugsnag-Span-Sampling"]);
}

- (void)testPValueHistogram11 {
    auto encoder = [self newEncoder];
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[self spanWithName:@"test0"
                                traceId:tid
                                 spanId:1
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test1"
                                traceId:tid
                                 spanId:2
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test2"
                                traceId:tid
                                 spanId:3
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test3"
                                traceId:tid
                                 spanId:4
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test4"
                                traceId:tid
                                 spanId:5
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test5"
                                traceId:tid
                                 spanId:6
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test6"
                                traceId:tid
                                 spanId:7
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test7"
                                traceId:tid
                                 spanId:8
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test8"
                                traceId:tid
                                 spanId:9
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test9"
                                traceId:tid
                                 spanId:10
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test10"
                                traceId:tid
                                 spanId:11
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
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
    auto package = encoder->buildUploadPackage(spans, resourceAttributes, true);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertEqualObjects(@"0:1;0.1:1;0.2:1;0.3:1;0.4:1;0.5:1;0.6:1;0.7:1;0.8:1;0.9:1;1:1", headers[@"Bugsnag-Span-Sampling"]);
}

- (void)testPValueWithoutHistogram {
    auto encoder = [self newEncoder];
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [[NSMutableArray alloc] init];
    TraceId tid = {.value=1};
    [spans addObject:[self spanWithName:@"test1"
                                traceId:tid
                                 spanId:1
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test2"
                                traceId:tid
                                 spanId:2
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test3"
                                traceId:tid
                                 spanId:3
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test4"
                                traceId:tid
                                 spanId:4
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans addObject:[self spanWithName:@"test5"
                                traceId:tid
                                 spanId:5
                               parentId:0
                              startTime:0
                             firstClass:BSGFirstClassUnset]];
    [spans[0] updateSamplingProbability:0.3];
    [spans[1] updateSamplingProbability:0.1];
    [spans[2] updateSamplingProbability:0.3];
    [spans[3] updateSamplingProbability:0.5];
    [spans[4] updateSamplingProbability:0.1];

    auto resourceAttributes = @{};
    auto package = encoder->buildUploadPackage(spans, resourceAttributes, false);

    auto headers = package->getHeadersForUnitTest();
    XCTAssertNil(headers[@"Bugsnag-Span-Sampling"]);
}

@end
