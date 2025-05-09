//
//  CrossTalkTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 14.05.24.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "BugsnagPerformanceCrossTalkAPI.h"
#import <BugsnagPerformance/BugsnagPerformance.h>
#import "BugsnagPerformanceSpan+Private.h"
#import "IdGenerator.h"

typedef void (^AppStartCallback)(BugsnagPerformanceSpan *);
typedef void (^ViewLoadCallback)(BugsnagPerformanceSpan *, UIViewController *);

// ============================================================================

#pragma mark Example CrossTalk API client. Use this as a template.

/**
 * An example CrossTalk client as would be written in a client library.
 */
@interface ExampleBugsnagPerformanceCrossTalkAPIClient: NSObject

#pragma mark APIs that all CrossTalk clients must implement

/**
 * This will be automatically called by the Objective-C runtime.
 */
+ (void)initialize;

/**
 * Get the shared instance. This will be nil if the host CrossTalk API wasn't found.
 */
+ (instancetype _Nullable)sharedInstance;

/**
 * Map a named API to a method with the specified selector.
 *
 * If an error occurs, the user info dictionary will contain the following NSNumber (boolean) fields:
 *  - "isSafeToCall": If @(YES), this method is safe to call (it has an implementation). Otherwise, calling it WILL throw a selector-not-found exception.
 *  - "willNOOP": If @(YES), calling the mapped method will no-op.
 *
 * Common scenarios:
 *  - The host library isn't linked in: isSafeToCall = YES, willNOOP = YES
 *  - apiName doesn't exist: isSafeToCall = YES, willNOOP = YES
 *  - toSelector already exists: isSafeToCall = YES, willNOOP = NO
 *  - Tried to map the same thing twice: isSafeToCall = YES, willNOOP = NO
 *  - Selector signature clash: isSafeToCall = NO, willNOOP = NO
 */
+ (NSError *)mapAPINamed:(NSString * _Nonnull)apiName toSelector:(SEL)toSelector;

#pragma mark Mapped API Methods that we'll be using

// Do NOT make implementations for any of the selectors you'll be mapping to.

- (NSArray *) getCurrentTraceAndSpanId;
- (BugsnagPerformanceConfiguration *) getConfiguration;
- (BugsnagPerformanceSpan *) startSpan:(NSString *)name options:(BugsnagPerformanceSpanOptions *)options;
- (BugsnagPerformanceSpanOptions *) newSpanOptions;
- (BugsnagPerformanceSpanContext *) newSpanContext:(u_int64_t)traceIdHi traceIdLo:(u_int64_t)traceIdLo spanId:(u_int64_t)spanId;
- (void)addWillEndUIInitSpanCallback:(AppStartCallback)callback;
- (void)addWillEndViewLoadSpanCallback:(ViewLoadCallback)callback;
- (BugsnagPerformanceSpan *)findSpanForCategory:(NSString *)categoryName;

@end

// FOR UNIT TESTS ONLY. Do not do this in a real client!
@interface ExampleBugsnagPerformanceCrossTalkAPIClient ()
- (NSString *)returnStringTest;         // Existing "test" API for unit tests
- (void * _Nullable)internal_doNothing; // Guaranteed already implemented method
- (NSString *) shouldNotFindThisMethod; // Non-existent method
@end

// The compiler will consider this implementation incomplete because
// the mapped API methods (see above) won't exist at compile time.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation ExampleBugsnagPerformanceCrossTalkAPIClient

static NSString *hostApiClassName = @"BugsnagPerformanceCrossTalkAPI";
static id hostCrossTalkAPI = nil;

+ (void)initialize {
    // Fetch the CrossTalk API using its Objective-C class name
    Class cls = NSClassFromString(hostApiClassName);
    hostCrossTalkAPI = [cls sharedInstance];
}

+ (instancetype _Nullable)sharedInstance {
    return hostCrossTalkAPI;
}

static NSString *userInfoKeyIsSafeToCall = @"isSafeToCall";
static NSString *userInfoKeyWillNOOP = @"willNOOP";

+ (NSError *)mapAPINamed:(NSString * _Nonnull)apiName toSelector:(SEL)toSelector {
    if (hostCrossTalkAPI == nil) {
        return [NSError errorWithDomain:@"com.bugsnag.CrossTalk"
                                   code:0
                               userInfo:@{
            NSLocalizedDescriptionKey:[NSString stringWithFormat:@"API class not found: %@", hostApiClassName],
            userInfoKeyIsSafeToCall:@YES,
            userInfoKeyWillNOOP:@YES
         }];
    }
    // [mapAPINamed: toSelector:] is implemented in the host CrossTalk API
    return [[hostCrossTalkAPI class] mapAPINamed:apiName toSelector:toSelector];
}

@end
#pragma clang diagnostic pop

#pragma mark Above here is everything a CrossTalk client must implement.

// ============================================================================


#pragma mark Missing/misspelled CrossTalk API client (for unit testing).
@interface MissingBugsnagPerformanceCrossTalkAPIClient: NSObject
- (NSString *)returnStringTest;
@end
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation MissingBugsnagPerformanceCrossTalkAPIClient
static NSString *missingApiClassName = @"MissingBugsnagPerformanceCrossTalkAPI";
static id hostMissingCrossTalkAPI = nil;
+ (void)initialize {
    Class cls = NSClassFromString(missingApiClassName);
    hostMissingCrossTalkAPI = [cls sharedInstance];
}
+ (instancetype _Nullable)sharedInstance {
    return hostMissingCrossTalkAPI;
}
+ (NSError *)mapAPINamed:(NSString * _Nonnull)apiName toSelector:(SEL)toSelector {
    if (hostMissingCrossTalkAPI == nil) {
        return [NSError errorWithDomain:@"com.bugsnag.CrossTalk"
                                   code:0
                               userInfo:@{
            NSLocalizedDescriptionKey:[NSString stringWithFormat:@"API class not found: %@", missingApiClassName],
            userInfoKeyIsSafeToCall:@YES,
            userInfoKeyWillNOOP:@YES
         }];
    }
    return [[hostMissingCrossTalkAPI class] mapAPINamed:apiName toSelector:toSelector];
}
@end
#pragma clang diagnostic pop


#pragma mark Unit Tests

@interface CrossTalkTests : XCTestCase
@end

@implementation CrossTalkTests

#pragma mark Unit Tests: BugsnagPerformanceCrossTalkAPI Published APIs

// You MUST make one test per API and version. Declare a selector in CrossTalkAPI and write a test here.

- (void)testGetCurrentTraceAndSpanIdV1 {
    NSError *err = [ExampleBugsnagPerformanceCrossTalkAPIClient mapAPINamed:@"getCurrentTraceAndSpanIdV1" toSelector:@selector(getCurrentTraceAndSpanId)];
    XCTAssertNil(err);
    // Calling the API should work. We can't test the return value since it will return nil in this situation.
    [ExampleBugsnagPerformanceCrossTalkAPIClient.sharedInstance getCurrentTraceAndSpanId];
}

- (void)testGetConfigurationV1 {
    NSError *err = [ExampleBugsnagPerformanceCrossTalkAPIClient mapAPINamed:@"getConfigurationV1" toSelector:@selector(getConfiguration)];
    XCTAssertNil(err);
    // Calling the API should work. We can't test the return value since it will return nil in this situation.
    [ExampleBugsnagPerformanceCrossTalkAPIClient.sharedInstance getConfiguration];
}

- (void)testStartSpanV1 {
    NSError *err = [ExampleBugsnagPerformanceCrossTalkAPIClient mapAPINamed:@"startSpanV1:options:" toSelector:@selector(startSpan:options:)];
    XCTAssertNil(err);
    // Calling the API should work. We can't test the return value since it will return nil in this situation.
    BugsnagPerformanceSpanOptions *spanOptions = [BugsnagPerformanceSpanOptions new];
    [ExampleBugsnagPerformanceCrossTalkAPIClient.sharedInstance startSpan:@"test" options:spanOptions];
}

- (void)testNewSpanOptionsV1 {
    NSError *err = [ExampleBugsnagPerformanceCrossTalkAPIClient mapAPINamed:@"newSpanOptionsV1" toSelector:@selector(newSpanOptions)];
    XCTAssertNil(err);
    
    BugsnagPerformanceSpanOptions *spanOptions = [ExampleBugsnagPerformanceCrossTalkAPIClient.sharedInstance newSpanOptions];
    NSDate *startTime = [NSDate new];
    spanOptions.startTime = startTime;
    XCTAssertEqualObjects(spanOptions.startTime, startTime);
}

- (void)testNewSpanContextV1 {
    NSError *err = [ExampleBugsnagPerformanceCrossTalkAPIClient mapAPINamed:@"newSpanContextV1:traceIdLo:spanId:" toSelector:@selector(newSpanContext:traceIdLo:spanId:)];
    XCTAssertNil(err);
    
    u_int64_t traceIdHi = 1;
    u_int64_t traceIdLo = 2;
    SpanId spanId = 3;
    BugsnagPerformanceSpanContext *spanContext = [ExampleBugsnagPerformanceCrossTalkAPIClient.sharedInstance newSpanContext:traceIdHi traceIdLo:traceIdLo spanId:spanId];
    
    XCTAssertEqual(spanContext.traceIdHi, traceIdHi);
    XCTAssertEqual(spanContext.traceIdLo, traceIdLo);
    XCTAssertEqual(spanContext.spanId, spanId);
}

- (void)testAddWillEndUIInitSpanCallbackV1 {
    NSError *err = [ExampleBugsnagPerformanceCrossTalkAPIClient mapAPINamed:@"addWillEndUIInitSpanCallbackV1:" toSelector:@selector(addWillEndUIInitSpanCallback:)];
    XCTAssertNil(err);
    
    __block BOOL didCallWillEndUIInitSpan = NO;
    __block BugsnagPerformanceSpan *actualSpan;
    [ExampleBugsnagPerformanceCrossTalkAPIClient.sharedInstance addWillEndUIInitSpanCallback:^(BugsnagPerformanceSpan *span) {
        didCallWillEndUIInitSpan = YES;
        actualSpan = span;
    }];
    MetricsOptions metricsOptions;
    BugsnagPerformanceSpan *span = [[BugsnagPerformanceSpan alloc] initWithName:@"a"
                                                                        traceId:IdGenerator::generateTraceId()
                                                                         spanId:IdGenerator::generateSpanId()
                                                                       parentId:0
                                                                      startTime:0
                                                                     firstClass:BSGTriStateUnset
                                                            samplingProbability:1.0
                                                            attributeCountLimit:128
                                                                 metricsOptions:metricsOptions
                                                                   onSpanEndSet:^(BugsnagPerformanceSpan * _Nonnull) {}
                                                                   onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}
                                                                  onSpanBlocked:^BugsnagPerformanceSpanCondition * _Nullable (BugsnagPerformanceSpan * _Nonnull, NSTimeInterval) { return nil; }];
    [[BugsnagPerformanceCrossTalkAPI sharedInstance] willEndUIInitSpan:span];
    
    XCTAssertTrue(didCallWillEndUIInitSpan);
    XCTAssertEqual(actualSpan.spanId, span.spanId);
    XCTAssertEqual(actualSpan.traceId.hi, span.traceId.hi);
    XCTAssertEqual(actualSpan.traceId.lo, span.traceId.lo);
}

- (void)testAddWillEndViewLoadSpanCallbackV1 {
    NSError *err = [ExampleBugsnagPerformanceCrossTalkAPIClient mapAPINamed:@"addWillEndViewLoadSpanCallbackV1:" toSelector:@selector(addWillEndViewLoadSpanCallback:)];
    XCTAssertNil(err);
    __block BOOL didCallWillEndViewLoadSpan = NO;
    __block BugsnagPerformanceSpan *actualSpan;
    __block UIViewController *actualViewController;
    [ExampleBugsnagPerformanceCrossTalkAPIClient.sharedInstance addWillEndViewLoadSpanCallback:^(BugsnagPerformanceSpan *span, UIViewController *viewController) {
        didCallWillEndViewLoadSpan = YES;
        actualSpan = span;
        actualViewController = viewController;
    }];
    
    MetricsOptions metricsOptions;
    BugsnagPerformanceSpan *span = [[BugsnagPerformanceSpan alloc] initWithName:@"a"
                                                                        traceId:IdGenerator::generateTraceId()
                                                                         spanId:IdGenerator::generateSpanId()
                                                                       parentId:0
                                                                      startTime:0
                                                                     firstClass:BSGTriStateUnset
                                                            samplingProbability:1.0
                                                            attributeCountLimit:128
                                                                 metricsOptions:metricsOptions
                                                                   onSpanEndSet:^(BugsnagPerformanceSpan * _Nonnull) {}
                                                                   onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}
                                                                  onSpanBlocked:^BugsnagPerformanceSpanCondition * _Nullable (BugsnagPerformanceSpan * _Nonnull, NSTimeInterval) { return nil; }];
    UIViewController *viewController = [UIViewController new];
    [[BugsnagPerformanceCrossTalkAPI sharedInstance] willEndViewLoadSpan:span viewController:viewController];
    
    XCTAssertTrue(didCallWillEndViewLoadSpan);
    XCTAssertEqual(actualSpan.spanId, span.spanId);
    XCTAssertEqual(actualSpan.traceId.hi, span.traceId.hi);
    XCTAssertEqual(actualSpan.traceId.lo, span.traceId.lo);
    XCTAssertEqual(actualViewController, viewController);
}

- (void)testFindSpanForCategoryV1 {
    NSError *err = [ExampleBugsnagPerformanceCrossTalkAPIClient mapAPINamed:@"findSpanForCategoryV1:" toSelector:@selector(findSpanForCategory:)];
    XCTAssertNil(err);
    // Calling the API should work. We can't test the return value since it will return nil in this situation.
    [ExampleBugsnagPerformanceCrossTalkAPIClient.sharedInstance findSpanForCategory:@""];
}

#pragma mark Unit Tests: BugsnagPerformanceCrossTalkAPI published APIs (for unit testing support only)

- (void)testReturnStringTestV1 {
    // We expect this mapping to succeed
    XCTAssertNil([ExampleBugsnagPerformanceCrossTalkAPIClient mapAPINamed:@"returnStringTestV1" toSelector:@selector(returnStringTest)]);
    // Calling the API should work
    XCTAssertEqualObjects([ExampleBugsnagPerformanceCrossTalkAPIClient.sharedInstance returnStringTest], @"test");

    // Attempting to map it again should return an error and no-op
    NSError *err = [ExampleBugsnagPerformanceCrossTalkAPIClient mapAPINamed:@"returnStringTestV1" toSelector:@selector(returnStringTest)];
    // The API exists, but the selector already exists, so we get an error
    XCTAssertNotNil(err);
    XCTAssertEqualObjects(err.userInfo[userInfoKeyIsSafeToCall], @YES);
    XCTAssertEqualObjects(err.userInfo[userInfoKeyWillNOOP], @NO);

    // Calling the API should still work
    XCTAssertEqualObjects([ExampleBugsnagPerformanceCrossTalkAPIClient.sharedInstance returnStringTest], @"test");
}

#pragma mark Unit Tests: BugsnagPerformanceCrossTalkAPI fundamentals

- (void)testMissingClientInstantiation {
    MissingBugsnagPerformanceCrossTalkAPIClient *api = MissingBugsnagPerformanceCrossTalkAPIClient.sharedInstance;
    // Since "MissingBugsnagPerformanceCrossTalkAPI" doesn't exist, we should have no API object
    XCTAssertNil(api);

    // If we try to map something, we get an error, but the API can be called (and will no-op)
    NSError *err = [MissingBugsnagPerformanceCrossTalkAPIClient mapAPINamed:@"returnStringTestV1" toSelector:@selector(returnStringTest)];
    XCTAssertNotNil(err);
    XCTAssertEqualObjects(err.userInfo[userInfoKeyIsSafeToCall], @YES);
    XCTAssertEqualObjects(err.userInfo[userInfoKeyWillNOOP], @YES);

    XCTAssertNil([MissingBugsnagPerformanceCrossTalkAPIClient.sharedInstance returnStringTest]);
}

- (void)testClientInstantiation {
    ExampleBugsnagPerformanceCrossTalkAPIClient *api = ExampleBugsnagPerformanceCrossTalkAPIClient.sharedInstance;
    // sharedInstance will be nil if we couldn't find the CrossTalk API class.
    XCTAssertNotNil(api);
}

- (void)testAPINotFound {
    NSError *err = [ExampleBugsnagPerformanceCrossTalkAPIClient mapAPINamed:@"shouldNotFindThisMethod" toSelector:@selector(shouldNotFindThisMethod)];
    XCTAssertNotNil(err);
    XCTAssertEqualObjects(err.userInfo[userInfoKeyIsSafeToCall], @YES);
    XCTAssertEqualObjects(err.userInfo[userInfoKeyWillNOOP], @YES);

    // It should still execute without crashing, even though it will do nothing and return nil.
    XCTAssertNil([ExampleBugsnagPerformanceCrossTalkAPIClient.sharedInstance shouldNotFindThisMethod]);
}

- (void)testAPIAlreadyExists {
    // internal_doNothing already exists, so we'll use it for our test
    NSError *err = [ExampleBugsnagPerformanceCrossTalkAPIClient mapAPINamed:@"getCurrentTraceAndSpanIdV1" toSelector:@selector(internal_doNothing)];
    XCTAssertNotNil(err);
    XCTAssertEqualObjects(err.userInfo[userInfoKeyIsSafeToCall], @YES);
    XCTAssertEqualObjects(err.userInfo[userInfoKeyWillNOOP], @NO);

    // The existing API should still work.
    XCTAssertEqual([ExampleBugsnagPerformanceCrossTalkAPIClient.sharedInstance internal_doNothing], nullptr);
}

#pragma mark Unit Tests: BugsnagPerformanceCrossTalkProxiedObject

- (void)testProxyNilObject {
    BugsnagPerformanceSpanOptions *proxy = (BugsnagPerformanceSpanOptions *)[BugsnagPerformanceCrossTalkProxiedObject proxied:nil];
    proxy.startTime = [NSDate new];
    // A proxy to nil will no-op and return null values.
    XCTAssertNil(proxy.startTime);
}

- (void)testProxyNonExistentClassAPI {
    BugsnagPerformanceSpanOptions *proxy = (BugsnagPerformanceSpanOptions *)[BugsnagPerformanceCrossTalkProxiedObject proxied:[NSObject new]];
    proxy.startTime = [NSDate new];
    // Since NSObject doesn't have a "startTime" property, the proxy will no-op and return null values.
    XCTAssertNil(proxy.startTime);
}

- (void)testProxyExistingClassAPI {
    BugsnagPerformanceSpanOptions *proxy = (BugsnagPerformanceSpanOptions *)[BugsnagPerformanceCrossTalkProxiedObject proxied:[BugsnagPerformanceSpanOptions new]];
    NSDate *startTime = [NSDate new];
    proxy.startTime = startTime;
    // Since BugsnagPerformanceSpanOptions does have a "startTime" property, we expect it to work.
    XCTAssertEqualObjects(proxy.startTime, startTime);
}

@end
