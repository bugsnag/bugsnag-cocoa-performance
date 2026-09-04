//
//  DiskIOSnapshotTests.mm
//  BugsnagPerformance
//
//  Created by gaurav agarawal on 03/08/26.
//  Copyright © 2026 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "../../Sources/BugsnagPerformance/Private/DiskIO/BSGDiskIOSnapshot.h"

// TEMP: flow logs so each test narrates its steps in the test console output.
// Uses fprintf(stderr) so xcodebuild's captured stdout/stderr picks it up
// (NSLog goes to os_log and is NOT captured by xcodebuild output redirection).
#define BSG_TEST_LOG(fmt, ...) do { \
    NSString *__msg = [NSString stringWithFormat:(@"[DiskIOTest] " fmt "\n"), ##__VA_ARGS__]; \
    fputs(__msg.UTF8String, stderr); fflush(stderr); \
    NSLog(@"[DiskIOTest] " fmt, ##__VA_ARGS__); \
} while (0)

@interface DiskIOSnapshotTests : XCTestCase
@end

@implementation DiskIOSnapshotTests

- (void)setUp {
    BSG_TEST_LOG(@"=== BEGIN %@ ===", NSStringFromSelector(self.invocation.selector));
}

- (void)tearDown {
    BSG_TEST_LOG(@"=== END   %@ ===", NSStringFromSelector(self.invocation.selector));
}

- (void)testCaptureReturnsValidSnapshot {
    BSG_TEST_LOG(@"Step 1: calling BSGCaptureDiskIOSnapshot()");
    BSGDiskIOSnapshot snapshot = BSGCaptureDiskIOSnapshot();
    BSG_TEST_LOG(@"Step 2: got snapshot valid=%d t=%.4f bytesRead=%llu bytesWritten=%llu",
                 snapshot.valid,
                 snapshot.timestamp,
                 (unsigned long long)snapshot.bytesRead,
                 (unsigned long long)snapshot.bytesWritten);

    XCTAssertTrue(snapshot.valid,
                  @"proc_pid_rusage(RUSAGE_INFO_V4) is expected to succeed for the "
                  @"current process on iOS/simulator; got valid=false");
    XCTAssertGreaterThan(snapshot.timestamp, 0.0);
}

- (void)testTimestampsAreMonotonicAcrossCaptures {
    BSG_TEST_LOG(@"Step 1: capturing first snapshot");
    BSGDiskIOSnapshot first = BSGCaptureDiskIOSnapshot();
    BSG_TEST_LOG(@"Step 2: capturing second snapshot");
    BSGDiskIOSnapshot second = BSGCaptureDiskIOSnapshot();
    if (!first.valid || !second.valid) {
        BSG_TEST_LOG(@"Step 3: SKIPPING assertion (one snapshot invalid: first=%d second=%d)",
                     first.valid, second.valid);
        return;
    }
    BSG_TEST_LOG(@"Step 3: asserting second.t (%.4f) >= first.t (%.4f)",
                 second.timestamp, first.timestamp);
    XCTAssertGreaterThanOrEqual(second.timestamp, first.timestamp);
}

- (void)testByteCountersAreMonotonicOverASmallWrite {
    BSG_TEST_LOG(@"Step 1: capturing BEFORE snapshot");
    BSGDiskIOSnapshot before = BSGCaptureDiskIOSnapshot();
    if (!before.valid) {
        BSG_TEST_LOG(@"Step 2: SKIPPING (before snapshot invalid)");
        return;
    }
    BSG_TEST_LOG(@"Step 2: BEFORE bytesRead=%llu bytesWritten=%llu",
                 (unsigned long long)before.bytesRead,
                 (unsigned long long)before.bytesWritten);

    // Force a small amount of real disk write to bump ri_diskio_byteswritten.
    NSString *tmp = [NSTemporaryDirectory() stringByAppendingPathComponent:
                     [NSString stringWithFormat:@"bsg-diskio-%u.bin", arc4random()]];
    NSMutableData *payload = [NSMutableData dataWithLength:64 * 1024];
    NSError *error = nil;
    BSG_TEST_LOG(@"Step 3: writing 64 KB to %@", tmp);
    [payload writeToFile:tmp options:NSDataWritingAtomic error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:tmp error:nil];

    BSG_TEST_LOG(@"Step 4: capturing AFTER snapshot");
    BSGDiskIOSnapshot after = BSGCaptureDiskIOSnapshot();
    if (!after.valid) {
        BSG_TEST_LOG(@"Step 5: SKIPPING (after snapshot invalid)");
        return;
    }
    BSG_TEST_LOG(@"Step 5: AFTER bytesRead=%llu (delta=%lld) bytesWritten=%llu (delta=%lld)",
                 (unsigned long long)after.bytesRead,
                 (long long)after.bytesRead - (long long)before.bytesRead,
                 (unsigned long long)after.bytesWritten,
                 (long long)after.bytesWritten - (long long)before.bytesWritten);

    // Counters are process-wide and monotonic: end must not go backwards.
    XCTAssertGreaterThanOrEqual(after.bytesRead, before.bytesRead);
    XCTAssertGreaterThanOrEqual(after.bytesWritten, before.bytesWritten);
}

@end
