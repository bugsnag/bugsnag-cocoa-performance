#import <XCTest/XCTest.h>
#import "EarlyConfiguration.h"

@interface EarlyConfigurationInfoPlistTests : XCTestCase

@end

@implementation EarlyConfigurationInfoPlistTests

- (void)testPrefersCapitalizedBugsnagKey {
    NSDictionary *infoDict = @{
        @"Bugsnag": @{
            @"performance": @{ @"disableSwizzling": @YES }
        },
        @"bugsnag": @{
            @"performance": @{ @"disableSwizzling": @NO }
        }
    };

    NSDictionary *result = [BSGEarlyConfiguration bsg_loadConfigFromInfoDictionary:infoDict];
    XCTAssertNotNil(result);
    NSDictionary *perf = result[@"performance"];
    XCTAssertEqualObjects(perf[@"disableSwizzling"], @YES);
}

- (void)testFallsBackToLowercaseBugsnagKey {
    NSDictionary *infoDict = @{
        @"bugsnag": @{
            @"performance": @{ @"disableSwizzling": @NO }
        }
    };

    NSDictionary *result = [BSGEarlyConfiguration bsg_loadConfigFromInfoDictionary:infoDict];
    XCTAssertNotNil(result);
    NSDictionary *perf = result[@"performance"];
    XCTAssertEqualObjects(perf[@"disableSwizzling"], @NO);
}

- (void)testNonDictionaryIsTreatedAsNil {
    NSDictionary *infoDict = @{
        @"Bugsnag": @123,
        @"bugsnag": @{
            @"performance": @{ @"disableSwizzling": @NO }
        }
    };

    NSDictionary *result = [BSGEarlyConfiguration bsg_loadConfigFromInfoDictionary:infoDict];
    // Capitalized key is not a dictionary, so it should fallback to lowercase
    XCTAssertNotNil(result);
    NSDictionary *perf = result[@"performance"];
    XCTAssertEqualObjects(perf[@"disableSwizzling"], @NO);
}

- (void)testMissingKeyReturnsNilOptions {
    NSDictionary *infoDict = @{
        @"SomeOtherKey": @{
            @"foo": @"bar"
        }
    };

    NSDictionary *result = [BSGEarlyConfiguration bsg_loadConfigFromInfoDictionary:infoDict];
    XCTAssertNil(result);
}

@end
