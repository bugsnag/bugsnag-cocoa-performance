//
//  CrossTalkTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 14.05.24.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>

@interface CrossTalkAPITester: NSObject

// Do NOT make implementations for any of these selectors.

- (NSString *) shouldNotFindThisMethod;

#pragma mark API Methods to Test

- (NSArray *) testingGetCurrentTraceAndSpanIdV1;

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation CrossTalkAPITester

static id crossTalkRealAPI = nil;

+ (void)initialize {
    Class cls = NSClassFromString(@"BugsnagPerformanceCrossTalkAPI");
    crossTalkRealAPI = [cls sharedInstance];
}

+ (instancetype _Nullable)sharedInstance {
    return crossTalkRealAPI;
}

+ (NSError *)mapAPINamed:(NSString * _Nonnull)apiName toSelector:(SEL)toSelector {
    return [[crossTalkRealAPI class] mapAPINamed:apiName toSelector:toSelector];
}

@end
#pragma clang diagnostic pop


@interface CrossTalkTests : XCTestCase
@end

@implementation CrossTalkTests

- (void)testClientInstantiation {
    CrossTalkAPITester *api = CrossTalkAPITester.sharedInstance;
    // sharedInstance will be nil if we couldn't find the API class.
    XCTAssertNotNil(api);
}

- (void)testAPINotFound {
    NSError *err = [CrossTalkAPITester mapAPINamed:@"shouldNotFindThisMethod" toSelector:@selector(shouldNotFindThisMethod)];
    // Should be mapped (to a null implementation)
    XCTAssertEqualObjects(err.userInfo[@"mapped"], @"YES");
    // It should still execute without crashing, even though it will do nothing and return nil.
    XCTAssertNil([CrossTalkAPITester.sharedInstance shouldNotFindThisMethod]);
}

// You MUST make one test per API and version. Declare a selector in CrossTalkAPI and write a test here.

- (void)testGetCurrentTraceAndSpanIdV1 {
    XCTAssertNil([CrossTalkAPITester mapAPINamed:@"getCurrentTraceAndSpanIdV1" toSelector:@selector(testingGetCurrentTraceAndSpanIdV1)]);
    [CrossTalkAPITester.sharedInstance testingGetCurrentTraceAndSpanIdV1];
}

@end
