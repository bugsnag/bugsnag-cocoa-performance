//
//  PersistentDeviceIDTest.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 16.06.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "FileBasedTest.h"
#import "PersistentDeviceID.h"
#import <memory.h>

using namespace bugsnag;

@interface PersistentDeviceIDTest : FileBasedTest

@end

@implementation PersistentDeviceIDTest

- (std::shared_ptr<PersistentDeviceID>)newDeviceID {
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"0123456789abcdef0123456789abcdef"];
    auto persistence = std::make_shared<Persistence>(self.filePath);
    auto deviceID = std::make_shared<PersistentDeviceID>(persistence);
    deviceID->earlyConfigure([BSGEarlyConfiguration new]);
    deviceID->earlySetup();
    deviceID->configure(config);
    deviceID->start();
    return deviceID;
}

- (void)testSavePath {
    // Force file creation if it hasn't happened already.
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"0123456789abcdef0123456789abcdef"];
    auto cachesPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    auto persistence = std::make_shared<Persistence>(cachesPath);
    auto deviceID = std::make_shared<PersistentDeviceID>(persistence);
    deviceID->earlyConfigure([BSGEarlyConfiguration new]);
    deviceID->earlySetup();
    deviceID->configure(config);
    deviceID->start();

    // Save path must be <caches-dir>/bugsnag-shared-<bundle-id>/device-id.json
    NSString *topLevelDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *dirPath = [topLevelDir stringByAppendingFormat:@"/bugsnag-shared-%@", [[NSBundle mainBundle] bundleIdentifier]];
    NSString *filePath = [dirPath stringByAppendingPathComponent:@"device-id.json"];

    NSFileManager *fm = [NSFileManager defaultManager];
    XCTAssertTrue([fm fileExistsAtPath:filePath]);
}

- (void)testGeneratesID {
    auto deviceID = [self newDeviceID];
    XCTAssertEqual(deviceID->external().length, (NSUInteger)40);
    XCTAssertEqual(deviceID->unittest_internal().length, (NSUInteger)40);
}

- (void)testExternalAndInternalAreDifferent {
    auto deviceID = [self newDeviceID];
    XCTAssertNotEqualObjects(deviceID->external(), deviceID->unittest_internal());
}

- (void)testGeneratesSameID {
    auto expected = [self newDeviceID];

    auto fm = [NSFileManager defaultManager];
    NSError *error = nil;
    [fm removeItemAtPath:self.filePath error:&error];
    XCTAssertNil(error);

    auto actual = [self newDeviceID];
    XCTAssertEqualObjects(expected->external(), actual->external());
    XCTAssertEqualObjects(expected->unittest_internal(), actual->unittest_internal());
}

- (void)testIDDoesNotChange {
    auto expected = [self newDeviceID];
    auto actual = [self newDeviceID];
    XCTAssertEqualObjects(expected->external(), actual->external());
    XCTAssertEqualObjects(expected->unittest_internal(), actual->unittest_internal());
}

@end
