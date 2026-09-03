//
//  DiskIOMetricsTests.mm
//  BugsnagPerformance
//
//  Created by gaurav agarawal on 03/08/26.
//  Copyright © 2026 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "../../Sources/BugsnagPerformance/Private/DiskIO/BSGDiskIOMetrics.h"
#import "../../Sources/BugsnagPerformance/Private/DiskIO/BSGDiskIOSnapshot.h"

// TEMP: flow logs so each test narrates its steps in the test console output.
// Uses fprintf(stderr) so xcodebuild's captured stdout/stderr picks it up
// (NSLog goes to os_log and is NOT captured by xcodebuild output redirection).
#define BSG_TEST_LOG(fmt, ...) do { \
    NSString *__msg = [NSString stringWithFormat:(@"[DiskIOTest] " fmt "\n"), ##__VA_ARGS__]; \
    fputs(__msg.UTF8String, stderr); fflush(stderr); \
    NSLog(@"[DiskIOTest] " fmt, ##__VA_ARGS__); \
} while (0)

static void logMetrics(const char *label, const BSGDiskIOMetrics &m) {
    NSString *msg = [NSString stringWithFormat:
        @"[DiskIOTest]   %s -> valid=%d iops_read=%lld iops_write=%lld iops_total=%lld\n",
        label, m.valid ? 1 : 0,
        (long long)m.iopsRead,
        (long long)m.iopsWrite,
        (long long)m.iopsTotal];
    fputs(msg.UTF8String, stderr); fflush(stderr);
    NSLog(@"%@", [msg stringByReplacingOccurrencesOfString:@"\n" withString:@""]);
}

@interface DiskIOMetricsTests : XCTestCase
@end

@implementation DiskIOMetricsTests

- (void)setUp {
    BSG_TEST_LOG(@"=== BEGIN %@ ===", NSStringFromSelector(self.invocation.selector));
}

- (void)tearDown {
    BSG_TEST_LOG(@"=== END   %@ ===", NSStringFromSelector(self.invocation.selector));
}

// The tests pin the block size explicitly rather than reading the host's real
// f_bsize, so expected values stay deterministic across simulators/devices.
static constexpr uint32_t kTestBlockSize = 4096;

static BSGDiskIOSnapshot makeSnapshot(CFAbsoluteTime t, uint64_t r, uint64_t w) {
    BSGDiskIOSnapshot s;
    s.timestamp = t;
    s.bytesRead = r;
    s.bytesWritten = w;
    s.blockSize = kTestBlockSize;
    s.valid = true;
    return s;
}

- (void)testKnownGoodDatasetFromScopingDoc {
    // 524288 bytes read + 262144 bytes written over 2s at 4 KB block size
    // -> read: 524288/4096 = 128 ops, 128/2 = 64 ops/sec
    // -> write: 262144/4096 = 64 ops, 64/2 = 32 ops/sec
    BSGDiskIOSnapshot start = makeSnapshot(0.0, 0, 0);
    BSGDiskIOSnapshot end = makeSnapshot(2.0, 524288, 262144);
    BSG_TEST_LOG(@"Step 1: input start(t=0 r=0 w=0), end(t=2 r=524288 w=262144)");

    BSGDiskIOMetrics metrics = BSGComputeDiskIOMetrics(start, end);
    logMetrics("Step 2: result", metrics);
    BSG_TEST_LOG(@"Step 3: expecting read=64 write=32 total=96");

    XCTAssertTrue(metrics.valid);
    XCTAssertEqual(metrics.iopsRead, 64);
    XCTAssertEqual(metrics.iopsWrite, 32);
    XCTAssertEqual(metrics.iopsTotal, 96);
}

- (void)testZeroDeltaProducesZeroIOPS {
    BSGDiskIOSnapshot start = makeSnapshot(0.0, 1000, 2000);
    BSGDiskIOSnapshot end = makeSnapshot(1.0, 1000, 2000);
    BSG_TEST_LOG(@"Step 1: input start(r=1000 w=2000), end same counters over 1s");

    BSGDiskIOMetrics metrics = BSGComputeDiskIOMetrics(start, end);
    logMetrics("Step 2: result", metrics);
    BSG_TEST_LOG(@"Step 3: expecting all zeros");

    XCTAssertTrue(metrics.valid);
    XCTAssertEqual(metrics.iopsRead, 0);
    XCTAssertEqual(metrics.iopsWrite, 0);
    XCTAssertEqual(metrics.iopsTotal, 0);
}

- (void)testZeroDurationReturnsInvalid {
    BSGDiskIOSnapshot start = makeSnapshot(5.0, 0, 0);
    BSGDiskIOSnapshot end = makeSnapshot(5.0, 524288, 262144);
    BSG_TEST_LOG(@"Step 1: input with duration = end.t (5.0) - start.t (5.0) = 0");

    BSGDiskIOMetrics metrics = BSGComputeDiskIOMetrics(start, end);
    logMetrics("Step 2: result", metrics);
    BSG_TEST_LOG(@"Step 3: expecting metrics.valid = false");
    XCTAssertFalse(metrics.valid);
}

- (void)testNegativeDurationReturnsInvalid {
    BSGDiskIOSnapshot start = makeSnapshot(10.0, 0, 0);
    BSGDiskIOSnapshot end = makeSnapshot(5.0, 524288, 262144);
    BSG_TEST_LOG(@"Step 1: input with negative duration (start.t=10 > end.t=5)");

    BSGDiskIOMetrics metrics = BSGComputeDiskIOMetrics(start, end);
    logMetrics("Step 2: result", metrics);
    BSG_TEST_LOG(@"Step 3: expecting metrics.valid = false");
    XCTAssertFalse(metrics.valid);
}

- (void)testInvalidStartSnapshotReturnsInvalid {
    BSGDiskIOSnapshot start;
    start.timestamp = 0.0;
    start.bytesRead = 0;
    start.bytesWritten = 0;
    start.blockSize = kTestBlockSize;
    start.valid = false;
    BSGDiskIOSnapshot end = makeSnapshot(2.0, 524288, 262144);
    BSG_TEST_LOG(@"Step 1: start snapshot marked invalid");

    BSGDiskIOMetrics metrics = BSGComputeDiskIOMetrics(start, end);
    logMetrics("Step 2: result", metrics);
    BSG_TEST_LOG(@"Step 3: expecting metrics.valid = false");
    XCTAssertFalse(metrics.valid);
}

- (void)testInvalidEndSnapshotReturnsInvalid {
    BSGDiskIOSnapshot start = makeSnapshot(0.0, 0, 0);
    BSGDiskIOSnapshot end;
    end.timestamp = 2.0;
    end.bytesRead = 524288;
    end.bytesWritten = 262144;
    end.blockSize = kTestBlockSize;
    end.valid = false;
    BSG_TEST_LOG(@"Step 1: end snapshot marked invalid");

    BSGDiskIOMetrics metrics = BSGComputeDiskIOMetrics(start, end);
    logMetrics("Step 2: result", metrics);
    BSG_TEST_LOG(@"Step 3: expecting metrics.valid = false");
    XCTAssertFalse(metrics.valid);
}

- (void)testZeroBlockSizeReturnsInvalid {
    // Defensive: a non-positive block size must never divide by zero.
    BSGDiskIOSnapshot start = makeSnapshot(0.0, 0, 0);
    BSGDiskIOSnapshot end = makeSnapshot(2.0, 524288, 262144);
    end.blockSize = 0;
    BSG_TEST_LOG(@"Step 1: end snapshot has blockSize = 0");

    BSGDiskIOMetrics metrics = BSGComputeDiskIOMetrics(start, end);
    logMetrics("Step 2: result", metrics);
    BSG_TEST_LOG(@"Step 3: expecting metrics.valid = false");
    XCTAssertFalse(metrics.valid);
}

- (void)testNegativeReadDeltaClampsToZero {
    // Counter regressed backwards (should never happen on the platform, but
    // handle it defensively).
    // write delta = 762144 - 500000 = 262144 -> 262144/4096 = 64 ops, /2s = 32
    BSGDiskIOSnapshot start = makeSnapshot(0.0, 1000000, 500000);
    BSGDiskIOSnapshot end = makeSnapshot(2.0, 900000, 762144);
    BSG_TEST_LOG(@"Step 1: read counter regressed (1000000 -> 900000); write went up by 262144 over 2s");

    BSGDiskIOMetrics metrics = BSGComputeDiskIOMetrics(start, end);
    logMetrics("Step 2: result", metrics);
    BSG_TEST_LOG(@"Step 3: expecting read=0 (clamped), write=32, total=32");

    XCTAssertTrue(metrics.valid);
    XCTAssertEqual(metrics.iopsRead, 0);
    XCTAssertEqual(metrics.iopsWrite, 32);
    XCTAssertEqual(metrics.iopsTotal, 32);
}

- (void)testRoundingUsesLlround {
    // 3072 bytes read over 1s at 4 KB block size -> 0.75 ops/sec -> rounds to 1.
    BSGDiskIOSnapshot start = makeSnapshot(0.0, 0, 0);
    BSGDiskIOSnapshot end = makeSnapshot(1.0, 3072, 0);
    BSG_TEST_LOG(@"Step 1: 3072 bytes read over 1s = 0.75 ops/sec (should round to 1)");

    BSGDiskIOMetrics metrics = BSGComputeDiskIOMetrics(start, end);
    logMetrics("Step 2: result", metrics);
    BSG_TEST_LOG(@"Step 3: expecting read=1, write=0, total=1");

    XCTAssertTrue(metrics.valid);
    XCTAssertEqual(metrics.iopsRead, 1);
    XCTAssertEqual(metrics.iopsWrite, 0);
    XCTAssertEqual(metrics.iopsTotal, 1);
}

- (void)testSubBlockDeltaRoundsToZero {
    // 1024 bytes read over 1s at 4 KB block size -> 0.25 ops/sec -> rounds to 0.
    BSGDiskIOSnapshot start = makeSnapshot(0.0, 0, 0);
    BSGDiskIOSnapshot end = makeSnapshot(1.0, 1024, 0);
    BSG_TEST_LOG(@"Step 1: 1024 bytes read over 1s = 0.25 ops/sec (should round to 0)");

    BSGDiskIOMetrics metrics = BSGComputeDiskIOMetrics(start, end);
    logMetrics("Step 2: result", metrics);
    BSG_TEST_LOG(@"Step 3: expecting all zeros (rounded)");

    XCTAssertTrue(metrics.valid);
    XCTAssertEqual(metrics.iopsRead, 0);
    XCTAssertEqual(metrics.iopsWrite, 0);
    XCTAssertEqual(metrics.iopsTotal, 0);
}

- (void)testShortSubSecondSpanStillComputesNormally {
    // 8192 bytes read + 8192 written over 0.1s at 4 KB -> 2 ops / 0.1s = 20 ops/sec.
    BSGDiskIOSnapshot start = makeSnapshot(0.0, 0, 0);
    BSGDiskIOSnapshot end = makeSnapshot(0.1, 8192, 8192);
    BSG_TEST_LOG(@"Step 1: 8192 R + 8192 W over 0.1s at 4 KB block -> 20 ops/sec each");

    BSGDiskIOMetrics metrics = BSGComputeDiskIOMetrics(start, end);
    logMetrics("Step 2: result", metrics);
    BSG_TEST_LOG(@"Step 3: expecting read=20, write=20, total=40");

    XCTAssertTrue(metrics.valid);
    XCTAssertEqual(metrics.iopsRead, 20);
    XCTAssertEqual(metrics.iopsWrite, 20);
    XCTAssertEqual(metrics.iopsTotal, 40);
}

- (void)testCapturedSnapshotUsesRealFilesystemBlockSize {
    // The live capture path must populate a positive block size (real f_bsize
    // or the 4 KB fallback) - never the old hardcoded 16 KB cluster size.
    BSGDiskIOSnapshot snapshot = BSGCaptureDiskIOSnapshot();
    BSG_TEST_LOG(@"Step 1: captured live snapshot, blockSize=%u", snapshot.blockSize);

    XCTAssertGreaterThan(snapshot.blockSize, 0u);
    XCTAssertEqual(snapshot.blockSize, BSGDiskBlockSizeBytes());
}

@end
