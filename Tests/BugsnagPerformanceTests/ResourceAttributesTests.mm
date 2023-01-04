//
//  ResourceAttributesTests.mm
//  BugsnagPerformance-iOSTests
//
//  Created by Nick Dowell on 02/11/2022.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "../../Sources/BugsnagPerformance/Private/ResourceAttributes.h"

using namespace bugsnag;

@interface ResourceAttributesTests : XCTestCase

@property(nonatomic,readwrite,strong) BugsnagPerformanceConfiguration *config;

@end

@implementation ResourceAttributesTests

- (void)setUp {
    NSError *error = nil;
    self.config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"0123456789abcdef0123456789abcdef" error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(self.config);
}

- (void)tearDown {
    self.config = nil;
}

- (void)testDeploymentEnvironment {
    auto attributes = ResourceAttributes(self.config).get();
    XCTAssertEqualObjects(attributes[@"deployment.environment"], @"development");
}

- (void)testDeploymentEnvironmentFromReleaseStage {
    self.config.releaseStage = @"staging";
    auto attributes = ResourceAttributes(self.config).get();
    XCTAssertEqualObjects(attributes[@"deployment.environment"], @"staging");
}

- (void)testDeviceModelIdentifier {
    auto attributes = ResourceAttributes(self.config).get();
    auto modelId = (NSString *)attributes[@"device.model.identifier"];
    XCTAssertGreaterThan(modelId.length, 0);
    XCTAssertTrue([modelId containsString:@","]);
    XCTAssertFalse([modelId containsString:@"\0"]);
}

@end
