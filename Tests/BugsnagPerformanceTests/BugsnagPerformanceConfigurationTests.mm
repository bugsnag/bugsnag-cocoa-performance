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
static NSString *const performanceEndpoint = @"PerformanceEndpoint";
static NSArray *const performanceEnabledReleaseStages = @[performanceReleaseStage1, performanceReleaseStage2];

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

- (void)testLoadConfigLoadsWhenAllValuesAreInPerformanceDictionary {
    auto config = [BugsnagPerformanceConfiguration loadConfigWithInfoDictionary:@{
        @"bugsnag": @{
            @"performance": @{
                @"apiKey": performanceApiKey,
                @"appVersion": performanceAppVersion,
                @"bundleVersion": performanceBundleVersion,
                @"releaseStage": performanceReleaseStage,
                @"enabledReleaseStages": performanceEnabledReleaseStages,
                @"endpoint": performanceEndpoint,
                @"autoInstrumentAppStarts": @(NO),
                @"autoInstrumentViewControllers": @(NO),
                @"autoInstrumentNetworkRequests": @(YES),
            }
        }
    }];
    XCTAssertEqual(config.apiKey, performanceApiKey);
    XCTAssertEqual(config.appVersion, performanceAppVersion);
    XCTAssertEqual(config.bundleVersion, performanceBundleVersion);
    XCTAssertEqual(config.releaseStage, performanceReleaseStage);
    XCTAssertEqual(config.enabledReleaseStages.count, performanceEnabledReleaseStages.count);
    XCTAssertTrue([config.enabledReleaseStages containsObject:performanceReleaseStage1]);
    XCTAssertTrue([config.enabledReleaseStages containsObject:performanceReleaseStage2]);
    XCTAssertEqual([config.endpoint description], performanceEndpoint);
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
                @"endpoint": performanceEndpoint,
                @"autoInstrumentAppStarts": @(NO),
                @"autoInstrumentViewControllers": @(NO),
                @"autoInstrumentNetworkRequests": @(YES),
            }
        }
    }];
    XCTAssertEqual(config.apiKey, performanceApiKey);
    XCTAssertEqual(config.appVersion, performanceAppVersion);
    XCTAssertEqual(config.bundleVersion, performanceBundleVersion);
    XCTAssertEqual(config.releaseStage, performanceReleaseStage);
    XCTAssertEqual(config.enabledReleaseStages.count, performanceEnabledReleaseStages.count);
    XCTAssertTrue([config.enabledReleaseStages containsObject:performanceReleaseStage1]);
    XCTAssertTrue([config.enabledReleaseStages containsObject:performanceReleaseStage2]);
    XCTAssertEqual([config.endpoint description], performanceEndpoint);
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
    XCTAssertEqual(config.apiKey, bugsnagApiKey);
    XCTAssertEqual(config.appVersion, bugsnagAppVersion);
    XCTAssertEqual(config.bundleVersion, bugsnagBundleVersion);
    XCTAssertEqual(config.releaseStage, bugsnagReleaseStage);
    XCTAssertEqual(config.enabledReleaseStages.count, bugsnagEnabledReleaseStages.count);
    XCTAssertTrue([config.enabledReleaseStages containsObject:bugsnagReleaseStage1]);
    XCTAssertTrue([config.enabledReleaseStages containsObject:bugsnagReleaseStage2]);
    XCTAssertEqual([config.endpoint description], performanceEndpoint);
    XCTAssertFalse(config.autoInstrumentAppStarts);
    XCTAssertFalse(config.autoInstrumentViewControllers);
    XCTAssertTrue(config.autoInstrumentNetworkRequests);
}

@end
