//
//  ResourceAttributesTests.mm
//  BugsnagPerformance-iOSTests
//
//  Created by Nick Dowell on 02/11/2022.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "../../Sources/BugsnagPerformance/Private/ResourceAttributes.h"
#import <memory>

using namespace bugsnag;

@interface ResourceAttributesTests : XCTestCase

@property(nonatomic,readwrite,strong) BugsnagPerformanceConfiguration *config;

@end

@implementation ResourceAttributesTests

- (void)setUp {
    NSError *error = nil;
    self.config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"0123456789abcdef0123456789abcdef"];
    XCTAssertNil(error);
    XCTAssertNotNil(self.config);
}

- (void)tearDown {
    self.config = nil;
}

- (std::shared_ptr<ResourceAttributes>) resourceAttributesWithConfig:(BugsnagPerformanceConfiguration *)config {
    auto attributes = std::make_shared<ResourceAttributes>();
    attributes->earlyConfigure([BSGEarlyConfiguration new]);
    attributes->earlySetup();
    attributes->configure(config);
    attributes->start();
    return attributes;
}

- (void)testDeploymentEnvironment {
    auto attributes = [self resourceAttributesWithConfig:self.config]->get();
    XCTAssertEqualObjects(attributes[@"deployment.environment"], @"development");
}

- (void)testDeploymentEnvironmentFromReleaseStage {
    self.config.releaseStage = @"staging";
    auto attributes = [self resourceAttributesWithConfig:self.config]->get();
    XCTAssertEqualObjects(attributes[@"deployment.environment"], @"staging");
}

- (void)testDeviceModelIdentifier {
    auto attributes = [self resourceAttributesWithConfig:self.config]->get();
    auto modelId = (NSString *)attributes[@"device.model.identifier"];
    XCTAssertGreaterThan(modelId.length, 0U);
    XCTAssertTrue([modelId containsString:@","]);
    XCTAssertFalse([modelId containsString:@"\0"]);
}

@end
