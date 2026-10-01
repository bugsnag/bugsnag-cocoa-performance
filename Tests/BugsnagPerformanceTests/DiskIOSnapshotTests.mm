//
//  DiskIOSnapshotTests.mm
//  BugsnagPerformance
//
//  Experiment (not for the PR): the same file and target entry as the DiskIO
//  snapshot tests, but a trivial test that uses nothing from the SDK. If iOS 14
//  still fails, adding any test file breaks the iOS 14 runner; if it passes,
//  the cause is in what the DiskIO tests include or call.
//

#import <XCTest/XCTest.h>

@interface DiskIOSnapshotTests : XCTestCase
@end

@implementation DiskIOSnapshotTests

- (void)testTrivial {
    XCTAssertTrue(YES);
}

@end

