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

- (void)testGeneratesID {
    auto deviceID = [self newDeviceID]->current();
    XCTAssertEqual(deviceID.length, (NSUInteger)40);
}

- (void)testGeneratesSameID {
    auto expectedId = [self newDeviceID]->current();

    auto fm = [NSFileManager defaultManager];
    NSError *error = nil;
    [fm removeItemAtPath:self.filePath error:&error];
    XCTAssertNil(error);

    auto actualId = [self newDeviceID]->current();
    XCTAssertEqualObjects(expectedId, actualId);
}

- (void)testIDDoesNotChange {
    auto expectedId = [self newDeviceID]->current();
    auto actualId = [self newDeviceID]->current();
    XCTAssertEqualObjects(expectedId, actualId);
}

@end
