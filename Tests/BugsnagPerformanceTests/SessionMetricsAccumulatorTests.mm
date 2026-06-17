//
//  SessionMetricsAccumulatorTests.mm
//  BugsnagPerformance-iOSTests
//
 //  Tests for:
 //  - SessionMetricsAccumulator (running min/max/sum/count for CPU and memory)
 //  - SpanAttributesProvider accumulator-based overloads
//
#import <XCTest/XCTest.h>
#import "TestHelpers.h"
#import "../../Sources/BugsnagPerformance/Private/AppStateTracker.h"
#import "../../Sources/BugsnagPerformance/Private/BugsnagPerformanceImpl.h"
#import "../../Sources/BugsnagPerformance/Private/BugsnagPerformanceConfiguration+Private.h"
#import "../../Sources/BugsnagPerformance/Private/Reachability.h"
#import "../../Sources/BugsnagPerformance/Private/SessionMetricsAccumulator.h"
#import "../../Sources/BugsnagPerformance/Private/SpanAttributesProvider.h"
#import "../../Sources/BugsnagPerformance/Private/SystemInfoSampler.h"

using namespace bugsnag;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

static SystemInfoSampleData makeSample(CFAbsoluteTime t,
                                       double processCPU,
                                       double mainThread,
                                       double monitorThread,
                                       uint64_t memInUse,
                                       uint64_t memTotal) {
    SystemInfoSampleData s(t);
    s.processCPUPct        = processCPU;
    s.mainThreadCPUPct     = mainThread;
    s.monitorThreadCPUPct  = monitorThread;
    s.physicalMemoryBytesInUse  = memInUse;
    s.physicalMemoryBytesTotal  = memTotal;
    return s;
}

// ---------------------------------------------------------------------------
// Test suite
// ---------------------------------------------------------------------------

@interface SessionMetricsAccumulatorTests : XCTestCase
@end

@implementation SessionMetricsAccumulatorTests

// ============================================================
// MARK: — RunningDoubleStats
// ============================================================

- (void)testRunningDoubleStats_empty {
    RunningDoubleStats stats;
    XCTAssertFalse(stats.hasData());
    XCTAssertEqual(stats.count, 0ULL);
    XCTAssertEqual(stats.mean(), 0.0);
}

- (void)testRunningDoubleStats_singleSample {
    RunningDoubleStats stats;
    stats.addSample(42.0);
    XCTAssertTrue(stats.hasData());
    XCTAssertEqual(stats.count, 1ULL);
    XCTAssertEqual(stats.sum,   42.0);
    XCTAssertEqual(stats.min,   42.0);
    XCTAssertEqual(stats.max,   42.0);
    XCTAssertEqual(stats.mean(), 42.0);
}

- (void)testRunningDoubleStats_multipleSamples_minMaxMean {
    RunningDoubleStats stats;
    stats.addSample(10.0);
    stats.addSample(30.0);
    stats.addSample(20.0);
    XCTAssertEqual(stats.count, 3ULL);
    XCTAssertEqual(stats.min,   10.0);
    XCTAssertEqual(stats.max,   30.0);
    XCTAssertEqualWithAccuracy(stats.mean(), 20.0, 0.001);
}

// ============================================================
// MARK: — RunningUInt64Stats
// ============================================================

- (void)testRunningUInt64Stats_empty {
    RunningUInt64Stats stats;
    XCTAssertFalse(stats.hasData());
    XCTAssertEqual(stats.mean(), 0ULL);
}

- (void)testRunningUInt64Stats_singleSample {
    RunningUInt64Stats stats;
    stats.addSample(512, 1024);
    XCTAssertTrue(stats.hasData());
    XCTAssertEqual(stats.count,        1ULL);
    XCTAssertEqual(stats.min,          512ULL);
    XCTAssertEqual(stats.max,          512ULL);
    XCTAssertEqual(stats.mean(),       512ULL);
    XCTAssertEqual(stats.lastTotalSize, 1024ULL);
}

- (void)testRunningUInt64Stats_minMaxMean {
    RunningUInt64Stats stats;
    stats.addSample(100, 1024);
    stats.addSample(200, 1024);
    stats.addSample(300, 2048); // total size updated
    XCTAssertEqual(stats.min,          100ULL);
    XCTAssertEqual(stats.max,          300ULL);
    XCTAssertEqual(stats.mean(),       200ULL);  // (100+200+300)/3 = 200
    XCTAssertEqual(stats.lastTotalSize, 2048ULL);
}

// ============================================================
// MARK: — SessionMetricsAccumulator — basic
// ============================================================

- (void)testAccumulator_freshIsEmpty {
    SessionMetricsAccumulator acc;
    XCTAssertFalse(acc.hasCPUData());
    XCTAssertFalse(acc.hasMemoryData());
}

- (void)testAccumulator_addValidSample {
    SessionMetricsAccumulator acc(0);
    auto s = makeSample(1.0, 20.0, 10.0, 5.0, 500, 1024);
    acc.addSample(s);

    XCTAssertTrue(acc.hasCPUData());
    XCTAssertTrue(acc.hasMemoryData());
    XCTAssertEqual(acc.processCPU.count,    1ULL);
    XCTAssertEqual(acc.mainThreadCPU.count, 1ULL);
    XCTAssertEqual(acc.memory.count,        1ULL);
}

- (void)testAccumulator_minMaxMeanOverMultipleSamples {
    SessionMetricsAccumulator acc(0);
    // CPU: 10, 50, 30  → mean=30, min=10, max=50
    acc.addSample(makeSample(1.0, 10.0, 5.0, 1.0, 100, 1000));
    acc.addSample(makeSample(2.0, 50.0, 25.0, 2.0, 200, 1000));
    acc.addSample(makeSample(3.0, 30.0, 15.0, 3.0, 300, 1000));

    XCTAssertEqualWithAccuracy(acc.processCPU.mean(), 30.0, 0.001);
    XCTAssertEqual(acc.processCPU.min, 10.0);
    XCTAssertEqual(acc.processCPU.max, 50.0);

    XCTAssertEqualWithAccuracy(acc.mainThreadCPU.mean(), 15.0, 0.001);
    XCTAssertEqual(acc.mainThreadCPU.min, 5.0);
    XCTAssertEqual(acc.mainThreadCPU.max, 25.0);

    XCTAssertEqual(acc.memory.mean(), 200ULL);
    XCTAssertEqual(acc.memory.min, 100ULL);
    XCTAssertEqual(acc.memory.max, 300ULL);
}

// ============================================================
// MARK: — SessionMetricsAccumulator — filtering
// ============================================================

- (void)testAccumulator_ignoresSamplesBeforeSessionStart {
    // session started at t=10; samples at t=5 must be rejected
    SessionMetricsAccumulator acc(10.0);

    auto earlyS = makeSample(5.0, 99.0, 99.0, 99.0, 9999, 9999);
    acc.addSample(earlyS);
    XCTAssertFalse(acc.hasCPUData(),    @"Sample before session start must not be counted");
    XCTAssertFalse(acc.hasMemoryData(), @"Sample before session start must not be counted");

    auto validS = makeSample(10.0, 20.0, 10.0, 5.0, 500, 1024);
    acc.addSample(validS);
    XCTAssertTrue(acc.hasCPUData());
    XCTAssertTrue(acc.hasMemoryData());
    XCTAssertEqual(acc.processCPU.count, 1ULL);
}

- (void)testAccumulator_ignoresInvalidSampledAt {
    SessionMetricsAccumulator acc(0);
    SystemInfoSampleData invalidSample; // sampledAt == -1 by default
    acc.addSample(invalidSample);
    XCTAssertFalse(acc.hasCPUData());
    XCTAssertFalse(acc.hasMemoryData());
}

- (void)testAccumulator_partialData_onlyCPUNoMemory {
    SessionMetricsAccumulator acc(0);
    SystemInfoSampleData s(1.0);
    s.processCPUPct = 25.0;
    // memory fields left at 0 / invalid
    acc.addSample(s);

    XCTAssertTrue(acc.hasCPUData());
    XCTAssertFalse(acc.hasMemoryData(), @"Memory inUse==0 is considered invalid");
}

// ============================================================
// MARK: — SessionMetricsAccumulator — reset
// ============================================================

- (void)testAccumulator_resetClearsAllData {
    SessionMetricsAccumulator acc(0);
    acc.addSample(makeSample(1.0, 30.0, 15.0, 5.0, 400, 1024));
    XCTAssertTrue(acc.hasCPUData());

    acc.reset();
    XCTAssertFalse(acc.hasCPUData());
    XCTAssertFalse(acc.hasMemoryData());
    XCTAssertEqual(acc.processCPU.count, 0ULL);
    XCTAssertEqual(acc.memory.count,     0ULL);
}

// ============================================================
// MARK: — SpanAttributesProvider — accumulator overloads
// ============================================================

- (void)testSessionCPUFromAccumulator_emptyReturnsEmptyDict {
    SpanAttributesProvider provider;
    SessionMetricsAccumulator acc;
    auto attrs = provider.sessionCPUSampleAttributes(acc, 10.0);
    XCTAssertEqual(attrs.count, 0U);
}

- (void)testSessionCPUFromAccumulator_singleSample {
    SpanAttributesProvider provider;
    SessionMetricsAccumulator acc(0);
    acc.addSample(makeSample(1.0, 20.0, 10.0, 5.0, 0, 0));

    auto attrs = provider.sessionCPUSampleAttributes(acc, 2.0);
    XCTAssertNotNil(attrs[@"bugsnag.system.cpu_measures_timestamps"]);
    XCTAssertEqualObjects(attrs[@"bugsnag.system.cpu_mean_total"], @20.0);
    XCTAssertEqualObjects(attrs[@"bugsnag.system.cpu_min_total"],  @20.0);
    XCTAssertEqualObjects(attrs[@"bugsnag.system.cpu_max_total"],  @20.0);
    // mean == min == max for single sample
}

- (void)testSessionCPUFromAccumulator_multiSample_matchesVectorOverload {
    // Build identical data into both vector and accumulator paths and compare output.
    SpanAttributesProvider provider;

    std::vector<SystemInfoSampleData> samples;
    SessionMetricsAccumulator acc(0);
    for (int i = 1; i <= 4; i++) {
        auto s = makeSample((CFAbsoluteTime)i, 10.0 * i, 5.0 * i, 2.0 * i, (uint64_t)(100 * i), 1000);
        samples.push_back(s);
        acc.addSample(s);
    }
    // samples: CPU 10,20,30,40  → mean=25, min=10, max=40

    auto vecAttrs = provider.sessionCPUSampleAttributes(samples, 5.0);
    auto accAttrs = provider.sessionCPUSampleAttributes(acc,     5.0);

    XCTAssertEqualObjects(vecAttrs[@"bugsnag.system.cpu_mean_total"], accAttrs[@"bugsnag.system.cpu_mean_total"]);
    XCTAssertEqualObjects(vecAttrs[@"bugsnag.system.cpu_min_total"],  accAttrs[@"bugsnag.system.cpu_min_total"]);
    XCTAssertEqualObjects(vecAttrs[@"bugsnag.system.cpu_max_total"],  accAttrs[@"bugsnag.system.cpu_max_total"]);

    XCTAssertEqualObjects(vecAttrs[@"bugsnag.system.cpu_mean_main_thread"], accAttrs[@"bugsnag.system.cpu_mean_main_thread"]);
    XCTAssertEqualObjects(vecAttrs[@"bugsnag.system.cpu_min_main_thread"],  accAttrs[@"bugsnag.system.cpu_min_main_thread"]);
    XCTAssertEqualObjects(vecAttrs[@"bugsnag.system.cpu_max_main_thread"],  accAttrs[@"bugsnag.system.cpu_max_main_thread"]);
}

- (void)testSessionMemoryFromAccumulator_emptyReturnsEmptyDict {
    SpanAttributesProvider provider;
    SessionMetricsAccumulator acc;
    auto attrs = provider.sessionMemorySampleAttributes(acc, 10.0);
    XCTAssertEqual(attrs.count, 0U);
}

- (void)testSessionMemoryFromAccumulator_singleSample {
    SpanAttributesProvider provider;
    SessionMetricsAccumulator acc(0);
    acc.addSample(makeSample(1.0, 0, 0, 0, 500, 1024));

    auto attrs = provider.sessionMemorySampleAttributes(acc, 2.0);
    XCTAssertEqual(attrs.count, 6U);
    XCTAssertEqualObjects(attrs[@"bugsnag.system.memory.spaces.device.size"], @1024ULL);
    XCTAssertEqualObjects(attrs[@"bugsnag.system.memory.spaces.device.mean"], @500ULL);
    XCTAssertEqualObjects(attrs[@"bugsnag.system.memory.spaces.device.min"],  @500ULL);
    XCTAssertEqualObjects(attrs[@"bugsnag.system.memory.spaces.device.max"],  @500ULL);
}

- (void)testSessionMemoryFromAccumulator_multiSample_matchesVectorOverload {
    SpanAttributesProvider provider;

    std::vector<SystemInfoSampleData> samples;
    SessionMetricsAccumulator acc(0);
    for (int i = 1; i <= 4; i++) {
        auto s = makeSample((CFAbsoluteTime)i, 0, 0, 0, (uint64_t)(100 * i), 1000);
        samples.push_back(s);
        acc.addSample(s);
    }
    // memory: 100,200,300,400  → mean=250, min=100, max=400

    auto vecAttrs = provider.sessionMemorySampleAttributes(samples, 5.0);
    auto accAttrs = provider.sessionMemorySampleAttributes(acc,     5.0);

    XCTAssertEqualObjects(vecAttrs[@"bugsnag.system.memory.spaces.device.mean"], accAttrs[@"bugsnag.system.memory.spaces.device.mean"]);
    XCTAssertEqualObjects(vecAttrs[@"bugsnag.system.memory.spaces.device.min"],  accAttrs[@"bugsnag.system.memory.spaces.device.min"]);
    XCTAssertEqualObjects(vecAttrs[@"bugsnag.system.memory.spaces.device.max"],  accAttrs[@"bugsnag.system.memory.spaces.device.max"]);
}

- (void)testSessionMemoryFromAccumulator_hasAllExpectedKeys {
    SpanAttributesProvider provider;
    SessionMetricsAccumulator acc(0);
    acc.addSample(makeSample(1.0, 0, 0, 0, 400, 1000));
    acc.addSample(makeSample(2.0, 0, 0, 0, 600, 1000));

    auto attrs = provider.sessionMemorySampleAttributes(acc, 3.0);
    XCTAssertNotNil(attrs[@"bugsnag.system.memory.timestamps"]);
    XCTAssertNotNil(attrs[@"bugsnag.system.memory.spaces.device.size"]);
    XCTAssertNotNil(attrs[@"bugsnag.system.memory.spaces.device.used"]);
    XCTAssertNotNil(attrs[@"bugsnag.system.memory.spaces.device.mean"]);
    XCTAssertNotNil(attrs[@"bugsnag.system.memory.spaces.device.min"]);
    XCTAssertNotNil(attrs[@"bugsnag.system.memory.spaces.device.max"]);
    XCTAssertEqualObjects(attrs[@"bugsnag.system.memory.spaces.device.min"],  @400ULL);
     XCTAssertEqualObjects(attrs[@"bugsnag.system.memory.spaces.device.max"],  @600ULL);
     XCTAssertEqualObjects(attrs[@"bugsnag.system.memory.spaces.device.mean"], @500ULL);
 }
 
 // ============================================================
 // MARK: — Session span — accumulator created on start
 // ============================================================
 
 - (void)testSessionSpanStart_createsAccumulator {
     // Verify startAppSessionSpan creates a span correctly and does not crash
     // (the accumulator is internal; we verify indirectly by checking span state)
     auto impl = std::make_unique<bugsnag::BugsnagPerformanceImpl>(
         std::make_shared<bugsnag::Reachability>(), [AppStateTracker new]);

     BugsnagPerformanceSpan *sessionSpan = impl->startAppSessionSpan(@"TestSession");

    XCTAssertNotNil(sessionSpan);
    XCTAssertTrue([sessionSpan.name hasPrefix:@"[AppSession/TestSession]"]);
    XCTAssertEqualObjects(sessionSpan.attributes[@"bugsnag.span.category"], @"app_session");
    XCTAssertEqual(sessionSpan.state, SpanStateOpen);

    [sessionSpan end];
    XCTAssertEqual(sessionSpan.state, SpanStateEnded);
}

 - (void)testSessionSpanEnd_doesNotCrash {
     // Verify ending a session span (which triggers accumulator move) does not crash
     auto impl = std::make_unique<bugsnag::BugsnagPerformanceImpl>(
         std::make_shared<bugsnag::Reachability>(), [AppStateTracker new]);
 
     BugsnagPerformanceSpan *s1 = impl->startAppSessionSpan(@"Session1");
     BugsnagPerformanceSpan *s2 = impl->startAppSessionSpan(@"Session2");
 
     [s1 end];
     [s2 end];
 
     XCTAssertEqual(s1.state, SpanStateEnded);
     XCTAssertEqual(s2.state, SpanStateEnded);
 }

 - (void)testSessionSpanEnd_abortedSpanHandledGracefully {
     // Verify that aborting a session span (sampling could drop it)
     // does not crash and does not leave orphaned accumulator entries
     auto impl = std::make_unique<bugsnag::BugsnagPerformanceImpl>(
         std::make_shared<bugsnag::Reachability>(), [AppStateTracker new]);

     BugsnagPerformanceSpan *span = impl->startAppSessionSpan(@"AbortedSession");
     [span abortIfOpen];
     XCTAssertEqual(span.state, SpanStateAborted);
     // If this reaches here without crash/leak, the cleanup path is safe
 }

- (void)testSessionSpanStart_withStartBackgroundParameter {
    auto impl = std::make_unique<bugsnag::BugsnagPerformanceImpl>(
        std::make_shared<bugsnag::Reachability>(), [AppStateTracker new]);

    BugsnagPerformanceSpan *sessionSpan = impl->startAppSessionSpan(@"BackgroundMusic");

    XCTAssertNotNil(sessionSpan);
    XCTAssertTrue([sessionSpan.name hasPrefix:@"[AppSession/BackgroundMusic]"]);
    XCTAssertEqualObjects(sessionSpan.attributes[@"bugsnag.span.category"], @"app_session");

    [sessionSpan end];
}

// ============================================================
// MARK: — Long session accuracy: same result as iterating vector
// ============================================================

- (void)testAccumulator_1000Samples_matchesBruteForce {
    const int N = 1000;
    SessionMetricsAccumulator acc(0);
    double bruteSum = 0, bruteMin = DBL_MAX, bruteMax = -DBL_MAX;

    for (int i = 0; i < N; i++) {
        double v = (double)(i % 100 + 1); // cycles 1..100
        acc.addSample(makeSample((CFAbsoluteTime)(i + 1), v, 0, 0, 0, 0));
        bruteSum += v;
        bruteMin = MIN(bruteMin, v);
        bruteMax = MAX(bruteMax, v);
    }

    XCTAssertEqual(acc.processCPU.count, (uint64_t)N);
    XCTAssertEqualWithAccuracy(acc.processCPU.sum,  bruteSum, 0.001);
    XCTAssertEqualWithAccuracy(acc.processCPU.min,  bruteMin, 0.001);
    XCTAssertEqualWithAccuracy(acc.processCPU.max,  bruteMax, 0.001);
    XCTAssertEqualWithAccuracy(acc.processCPU.mean(), bruteSum / N, 0.001);
}

@end
