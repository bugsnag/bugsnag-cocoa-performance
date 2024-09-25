//
//  BugsnagPerformanceConfigurationTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 04.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BugsnagPerformance/BugsnagPerformance.h>
#import "BugsnagPerformanceConfiguration+Private.h"

@interface BugsnagPerformanceConfigurationTests : XCTestCase

@end

@implementation BugsnagPerformanceConfigurationTests

static NSString *const performanceApiKey = @"PerfromanceApiKey";
static NSString *const performanceAppVersion = @"PerfromanceAppVersion";
static NSString *const performanceBundleVersion = @"PerformanceBundleVersion";
static NSString *const performanceReleaseStage = @"PerformanceReleaseStage";
static NSString *const performanceReleaseStage1 = @"PerformanceEnabledReleaseStage1";
static NSString *const performanceReleaseStage2 = @"PerformanceEnabledReleaseStage2";
static NSString *const performanceServiceName = @"PerformanceServiceName";
static NSString *const performanceEndpoint = @"PerformanceEndpoint";
static NSArray *const performanceEnabledReleaseStages = @[performanceReleaseStage1, performanceReleaseStage2];
static NSArray *const performanceTracePropagationUrls = @[@"https://my.company.com/.*", @"https://somewhere.com/[0-9]+/abc/*"];

static NSString *const bugsnagApiKey = @"PerfromanceApiKey";
static NSString *const bugsnagAppVersion = @"PerfromanceAppVersion";
static NSString *const bugsnagBundleVersion = @"PerformanceBundleVersion";
static NSString *const bugsnagReleaseStage = @"PerformanceReleaseStage";
static NSString *const bugsnagReleaseStage1 = @"PerformanceEnabledReleaseStage1";
static NSString *const bugsnagReleaseStage2 = @"PerformanceEnabledReleaseStage2";
static NSArray *const bugsnagEnabledReleaseStages = @[bugsnagReleaseStage1, bugsnagReleaseStage2];

- (void)testShouldPassValidationWithCorrectApiKeyAndDefaultEndpoint {
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"0123456789abcdef0123456789abcdef"];
    NSError *error = nil;
    XCTAssertTrue([config validate:&error]);
    XCTAssertNil(error);
}

- (void)testShouldNotPassValidationWithAnExceptionWithEmptyApiKeyAndDefaultEndpoint {
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@""];
    NSError *error = nil;
    XCTAssertThrows([config validate:&error]);
}

- (void)testShouldNotPassValidationWithInvalidApiKeyAndDefaultEndpoint {
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"YOUR-API-KEY-HERE"];
    NSError *error = nil;
    XCTAssertFalse([config validate:&error]);
    XCTAssertNotNil(error);
}

- (void)testShouldPassValidationWithValidApiKeyAndValidCustomEndpoint {
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"0123456789abcdef0123456789abcdef"];
    config.endpoint = (NSURL *_Nonnull)[NSURL URLWithString:@"http://bugsnag.com"];
    NSError *error = nil;
    XCTAssertTrue([config validate:&error]);
    XCTAssertNil(error);
}

- (void)testShouldNotPassValidationWithValidApiKeyAndInvalidCustomEndpoint {
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"0123456789abcdef0123456789abcdef"];
    config.endpoint = (NSURL *_Nonnull)[NSURL URLWithString:@"x"];
    NSError *error = nil;
    XCTAssertFalse([config validate:&error]);
    XCTAssertNotNil(error);
}

- (void)testShouldSendReportsWhenEnabledReleaseStagesAreEmpty {
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"0123456789abcdef0123456789abcdef"];
    XCTAssertTrue([config shouldSendReports]);
}

- (void)testShouldSendReportsWhenEnabledReleaseStagesContainCurrentStage {
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"0123456789abcdef0123456789abcdef"];
    config.enabledReleaseStages = [NSSet setWithArray: @[@"env1", @"env2"]];
    config.releaseStage = @"env2";
    XCTAssertTrue([config shouldSendReports]);
}

- (void)testShouldNotSendReportsWhenEnabledReleaseStagesDontContainCurrentStage {
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"0123456789abcdef0123456789abcdef"];
    config.enabledReleaseStages = [NSSet setWithArray: @[@"env1", @"env2"]];
    config.releaseStage = @"env3";
    XCTAssertFalse([config shouldSendReports]);
}

- (void)assertConfig:(BugsnagPerformanceConfiguration *)config tracePropagationUrlsAre:(NSArray<NSString *> *) regexStrings {
    XCTAssertEqual(config.tracePropagationUrls.count, regexStrings.count);
    for(NSString *regexString: regexStrings) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:0 error:nil];
        XCTAssertTrue([config.tracePropagationUrls containsObject:regex]);
    }
}

- (void)testLoadConfigLoadsWhenAllValuesAreInPerformanceDictionary {
    auto config = [BugsnagPerformanceConfiguration loadConfigWithInfoDictionary:@{
        @"bugsnag": @{
            @"performance": @{
                @"apiKey": performanceApiKey,
                @"appVersion": performanceAppVersion,
                @"bundleVersion": performanceBundleVersion,
                @"releaseStage": performanceReleaseStage,
                @"enabledReleaseStages": performanceEnabledReleaseStages,
                @"serviceName": performanceServiceName,
                @"endpoint": performanceEndpoint,
                @"attributeArrayLengthLimit": @100,
                @"attributeStringValueLimit": @200,
                @"attributeCountLimit": @50,
                @"tracePropagationUrls": performanceTracePropagationUrls,
                @"autoInstrumentAppStarts": @(NO),
                @"autoInstrumentViewControllers": @(NO),
                @"autoInstrumentNetworkRequests": @(YES),
            }
        }
    }];
    XCTAssertEqualObjects(config.apiKey, performanceApiKey);
    XCTAssertEqualObjects(config.appVersion, performanceAppVersion);
    XCTAssertEqualObjects(config.bundleVersion, performanceBundleVersion);
    XCTAssertEqualObjects(config.releaseStage, performanceReleaseStage);
    XCTAssertEqual(config.enabledReleaseStages.count, performanceEnabledReleaseStages.count);
    XCTAssertTrue([config.enabledReleaseStages containsObject:performanceReleaseStage1]);
    XCTAssertTrue([config.enabledReleaseStages containsObject:performanceReleaseStage2]);
    XCTAssertEqualObjects([config.endpoint description], performanceEndpoint);
    XCTAssertEqual(config.attributeArrayLengthLimit, (NSUInteger)100);
    XCTAssertEqual(config.attributeStringValueLimit, (NSUInteger)200);
    XCTAssertEqual(config.attributeCountLimit, (NSUInteger)50);
    [self assertConfig:config tracePropagationUrlsAre:performanceTracePropagationUrls];
    XCTAssertFalse(config.autoInstrumentAppStarts);
    XCTAssertFalse(config.autoInstrumentViewControllers);
    XCTAssertTrue(config.autoInstrumentNetworkRequests);
}

- (void)testLoadConfigDoesntTakeValuesFromBugsnagWhenAllValuesAreInPerformanceDictionary {
    auto config = [BugsnagPerformanceConfiguration loadConfigWithInfoDictionary:@{
        @"bugsnag": @{
            @"apiKey": bugsnagApiKey,
            @"appVersion": bugsnagAppVersion,
            @"bundleVersion": bugsnagBundleVersion,
            @"releaseStage": bugsnagReleaseStage,
            @"enabledReleaseStages": bugsnagEnabledReleaseStages,
            @"performance": @{
                @"apiKey": performanceApiKey,
                @"appVersion": performanceAppVersion,
                @"bundleVersion": performanceBundleVersion,
                @"releaseStage": performanceReleaseStage,
                @"enabledReleaseStages": performanceEnabledReleaseStages,
                @"serviceName": performanceServiceName,
                @"endpoint": performanceEndpoint,
                @"attributeArrayLengthLimit": @100,
                @"attributeStringValueLimit": @200,
                @"attributeCountLimit": @50,
                @"tracePropagationUrls": performanceTracePropagationUrls,
                @"autoInstrumentAppStarts": @(NO),
                @"autoInstrumentViewControllers": @(NO),
                @"autoInstrumentNetworkRequests": @(YES),
            }
        }
    }];
    XCTAssertEqualObjects(config.apiKey, performanceApiKey);
    XCTAssertEqualObjects(config.appVersion, performanceAppVersion);
    XCTAssertEqualObjects(config.bundleVersion, performanceBundleVersion);
    XCTAssertEqualObjects(config.releaseStage, performanceReleaseStage);
    XCTAssertEqual(config.enabledReleaseStages.count, performanceEnabledReleaseStages.count);
    XCTAssertTrue([config.enabledReleaseStages containsObject:performanceReleaseStage1]);
    XCTAssertTrue([config.enabledReleaseStages containsObject:performanceReleaseStage2]);
    XCTAssertEqualObjects(config.serviceName, performanceServiceName);
    XCTAssertEqualObjects([config.endpoint description], performanceEndpoint);
    XCTAssertEqual(config.attributeArrayLengthLimit, (NSUInteger)100);
    XCTAssertEqual(config.attributeStringValueLimit, (NSUInteger)200);
    XCTAssertEqual(config.attributeCountLimit, (NSUInteger)50);
    [self assertConfig:config tracePropagationUrlsAre:performanceTracePropagationUrls];
    XCTAssertFalse(config.autoInstrumentAppStarts);
    XCTAssertFalse(config.autoInstrumentViewControllers);
    XCTAssertTrue(config.autoInstrumentNetworkRequests);
}

- (void)testLoadConfigDoesTakeValuesFromBugsnagWhenSomeValuesAreMissingInPerformanceDictionary {
    auto config = [BugsnagPerformanceConfiguration loadConfigWithInfoDictionary:@{
        @"bugsnag": @{
            @"apiKey": bugsnagApiKey,
            @"appVersion": bugsnagAppVersion,
            @"bundleVersion": bugsnagBundleVersion,
            @"releaseStage": bugsnagReleaseStage,
            @"enabledReleaseStages": bugsnagEnabledReleaseStages,
            @"performance": @{
                @"endpoint": performanceEndpoint,
                @"autoInstrumentAppStarts": @(NO),
                @"autoInstrumentViewControllers": @(NO),
                @"autoInstrumentNetworkRequests": @(YES),
            }
        }
    }];
    XCTAssertEqualObjects(config.apiKey, bugsnagApiKey);
    XCTAssertEqualObjects(config.appVersion, bugsnagAppVersion);
    XCTAssertEqualObjects(config.bundleVersion, bugsnagBundleVersion);
    XCTAssertEqualObjects(config.releaseStage, bugsnagReleaseStage);
    XCTAssertEqual(config.enabledReleaseStages.count, bugsnagEnabledReleaseStages.count);
    XCTAssertTrue([config.enabledReleaseStages containsObject:bugsnagReleaseStage1]);
    XCTAssertTrue([config.enabledReleaseStages containsObject:bugsnagReleaseStage2]);
    XCTAssertEqualObjects([config.endpoint description], performanceEndpoint);
    XCTAssertFalse(config.autoInstrumentAppStarts);
    XCTAssertFalse(config.autoInstrumentViewControllers);
    XCTAssertTrue(config.autoInstrumentNetworkRequests);
}

- (void)testShouldSetIncludeApiKeyInTheDefaultEndpoint {
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"0123456789abcdef0123456789abcdef"];
    XCTAssertEqualObjects(config.endpoint.absoluteString, @"https://0123456789abcdef0123456789abcdef.otlp.bugsnag.com/v1/traces");
}

- (void)testLimits {
#define MIN_ATTRIBUTE_COUNT_LIMIT (uint64_t)1
#define MAX_ATTRIBUTE_COUNT_LIMIT (uint64_t)500
#define DEFAULT_ATTRIBUTE_COUNT_LIMIT (uint64_t)100

#define MIN_ATTRIBUTE_ARRAY_LENGTH_LIMIT (uint64_t)1
#define MAX_ATTRIBUTE_ARRAY_LENGTH_LIMIT (uint64_t)10000
#define DEFAULT_ATTRIBUTE_ARRAY_LENGTH_LIMIT (uint64_t)1000

#define MIN_ATTRIBUTE_STRING_VALUE_LIMIT (uint64_t)1
#define MAX_ATTRIBUTE_STRING_VALUE_LIMIT (uint64_t)10000
#define DEFAULT_ATTRIBUTE_STRING_VALUE_LIMIT (uint64_t)1024

    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"0123456789abcdef0123456789abcdef"];
    XCTAssertEqual(config.attributeArrayLengthLimit, DEFAULT_ATTRIBUTE_ARRAY_LENGTH_LIMIT);
    XCTAssertEqual(config.attributeStringValueLimit, DEFAULT_ATTRIBUTE_STRING_VALUE_LIMIT);

    config.attributeArrayLengthLimit = MAX_ATTRIBUTE_ARRAY_LENGTH_LIMIT + 1;
    config.attributeStringValueLimit = MAX_ATTRIBUTE_STRING_VALUE_LIMIT + 1;
    XCTAssertEqual(config.attributeArrayLengthLimit, MAX_ATTRIBUTE_ARRAY_LENGTH_LIMIT);
    XCTAssertEqual(config.attributeStringValueLimit, MAX_ATTRIBUTE_STRING_VALUE_LIMIT);

    config.attributeArrayLengthLimit = 0;
    config.attributeStringValueLimit = 0;
    XCTAssertEqual(config.attributeArrayLengthLimit, DEFAULT_ATTRIBUTE_ARRAY_LENGTH_LIMIT);
    XCTAssertEqual(config.attributeStringValueLimit, DEFAULT_ATTRIBUTE_STRING_VALUE_LIMIT);
}

@end
