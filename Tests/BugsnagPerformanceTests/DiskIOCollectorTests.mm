//
//  DiskIOCollectorTests.mm
//  BugsnagPerformance
//
//  Created by gaurav agarawal on 03/08/26.
//  Copyright © 2026 Bugsnag. All rights reserved.
//

// this file as test-method clusters):
//   Scenario 1  (attribute emission)     -> testStartFollowedByEndReturnsThreeIOPSAttributes
//   Scenario 4  (negative delta, e2e hook) -> testNegativeDeltaFaultOmitsAttributes
//   Scenario 5  (source unavailable)     -> testFailAtStartFaultStoresNoStartSnapshotAndOmitsAttributes,
//                                           testFailAtEndFaultOmitsAttributesAndStillCleansUp,
//                                           testEndWithoutMatchingStartReturnsNil
//   Scenario 7  (concurrent spans)       -> testTwoSpansAreTrackedIndependently,
//                                           testConcurrentStartAndEndAreThreadSafe
//   Scenario 8  (orphaned snapshots)     -> testAbandonReleasesPendingStart
//   Scenario 12 (payload shape)          -> testTotalEqualsReadPlusWrite
//   PLAT-17203  (fault hook default)     -> testFaultModeDefaultsToNone
//   Scenarios 9/10/13 (lifecycle gating) -> DiskIOLifecycleGatingTests (below)

#import <XCTest/XCTest.h>

#import "../../Sources/BugsnagPerformance/Private/DiskIO/BSGDiskIOCollector.h"
#import "BugsnagPerformanceSpan+Private.h"
#import "IdGenerator.h"
#import "SpanOptions.h"
#import "../../Sources/BugsnagPerformance/Private/SpanLifecycle/SpanLifecycleHandlerImpl.h"
#import "../../Sources/BugsnagPerformance/Private/SpanStore/SpanStoreImpl.h"

// TEMP: flow logs so each test narrates its steps in the test console output.
// Uses fprintf(stderr) so xcodebuild's captured stdout/stderr picks it up
// (NSLog goes to os_log and is NOT captured by xcodebuild output redirection).
#define BSG_TEST_LOG(fmt, ...) do { \
    NSString *__msg = [NSString stringWithFormat:(@"[DiskIOTest] " fmt "\n"), ##__VA_ARGS__]; \
    fputs(__msg.UTF8String, stderr); fflush(stderr); \
    NSLog(@"[DiskIOTest] " fmt, ##__VA_ARGS__); \
} while (0)

using namespace bugsnag;

@interface DiskIOCollectorTests : XCTestCase
@end

@implementation DiskIOCollectorTests

- (void)setUp {
    BSG_TEST_LOG(@"=== BEGIN %@ ===", NSStringFromSelector(self.invocation.selector));
}

- (void)tearDown {
    BSG_TEST_LOG(@"=== END   %@ ===", NSStringFromSelector(self.invocation.selector));
}

static BugsnagPerformanceSpan *makeSpan() {
    MetricsOptions metricsOptions;
    TraceId tid = {.value = 1};
    return [[BugsnagPerformanceSpan alloc] initWithName:@"test"
                                                traceId:tid
                                                 spanId:IdGenerator::generateSpanId()
                                               parentId:IdGenerator::generateSpanId()
                                              startTime:SpanOptions().startTime
                                             firstClass:BSGTriStateYes
                                    samplingProbability:1.0
                                    attributeCountLimit:128
                                         metricsOptions:metricsOptions
                                 conditionsToEndOnClose:@[]
                                           onSpanEndSet:^(BugsnagPerformanceSpan * _Nonnull) {}
                                           onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}
                                          onSpanBlocked:^BugsnagPerformanceSpanCondition * _Nullable(BugsnagPerformanceSpan * _Nonnull, NSTimeInterval) { return nil; }
                                        onSpanCancelled:^(BugsnagPerformanceSpan * _Nonnull) {}];
}

- (void)testStartFollowedByEndReturnsThreeIOPSAttributes {
    BSG_TEST_LOG(@"Step 1: create collector + span");
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    BugsnagPerformanceSpan *span = makeSpan();

    BSG_TEST_LOG(@"Step 2: calling onSpanStart (spanId=%016llx)", (unsigned long long)span.spanId);
    [collector onSpanStart:span];
    BSG_TEST_LOG(@"Step 3: pending=%lu (expected 1)", (unsigned long)collector.pendingSpanCount);
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)1);

    // Ensure duration > 0 so metrics can be computed.
    BSG_TEST_LOG(@"Step 4: sleeping 10 ms so span duration > 0");
    [NSThread sleepForTimeInterval:0.01];

    BSG_TEST_LOG(@"Step 5: calling onSpanEnd");
    NSDictionary<NSString *, NSNumber *> *attrs = [collector onSpanEnd:span];
    BSG_TEST_LOG(@"Step 6: got %lu attributes: %@", (unsigned long)attrs.count, attrs);

    XCTAssertNotNil(attrs);
    XCTAssertNotNil(attrs[@"bugsnag.system.disk.iops_read"]);
    XCTAssertNotNil(attrs[@"bugsnag.system.disk.iops_write"]);
    XCTAssertNotNil(attrs[@"bugsnag.system.disk.iops_total"]);

    // Start entry must have been removed.
    BSG_TEST_LOG(@"Step 7: pending after end=%lu (expected 0)", (unsigned long)collector.pendingSpanCount);
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)0);
}

- (void)testTotalEqualsReadPlusWrite {
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    BugsnagPerformanceSpan *span = makeSpan();

    BSG_TEST_LOG(@"Step 1: onSpanStart + 10 ms sleep + onSpanEnd");
    [collector onSpanStart:span];
    [NSThread sleepForTimeInterval:0.01];
    NSDictionary<NSString *, NSNumber *> *attrs = [collector onSpanEnd:span];
    XCTAssertNotNil(attrs);

    int64_t r = attrs[@"bugsnag.system.disk.iops_read"].longLongValue;
    int64_t w = attrs[@"bugsnag.system.disk.iops_write"].longLongValue;
    int64_t t = attrs[@"bugsnag.system.disk.iops_total"].longLongValue;
    BSG_TEST_LOG(@"Step 2: r=%lld w=%lld t=%lld (expecting t == r + w)", r, w, t);
    XCTAssertEqual(t, r + w);
}

- (void)testDebugSnapshotsOmittedByDefault {
    // The raw-counter debug attributes are strictly test-only: with the flag
    // at its default, the returned dictionary must contain ONLY the three
    // canonical IOPS keys.
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    XCTAssertFalse(collector.attachDebugSnapshots);
    BugsnagPerformanceSpan *span = makeSpan();

    BSG_TEST_LOG(@"Step 1: onSpanStart + 10 ms sleep + onSpanEnd (flag default)");
    [collector onSpanStart:span];
    [NSThread sleepForTimeInterval:0.01];
    NSDictionary<NSString *, NSNumber *> *attrs = [collector onSpanEnd:span];
    XCTAssertNotNil(attrs);

    BSG_TEST_LOG(@"Step 2: got %lu attributes (expected exactly 3): %@", (unsigned long)attrs.count, attrs);
    XCTAssertEqual(attrs.count, (NSUInteger)3);
    XCTAssertNil(attrs[BSGDiskIODebugAttributeKeyReadStart]);
    XCTAssertNil(attrs[BSGDiskIODebugAttributeKeyReadEnd]);
    XCTAssertNil(attrs[BSGDiskIODebugAttributeKeyWriteStart]);
    XCTAssertNil(attrs[BSGDiskIODebugAttributeKeyWriteEnd]);
}

- (void)testAttachDebugSnapshotsAddsOrderedRawCounters {
    // With the test-only flag enabled the result gains the four raw counter
    // keys, and the counters must be ordered start <= end (the platform
    // counters are monotonic within a process).
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    collector.attachDebugSnapshots = YES;
    BugsnagPerformanceSpan *span = makeSpan();

    BSG_TEST_LOG(@"Step 1: onSpanStart + 10 ms sleep + onSpanEnd (flag enabled)");
    [collector onSpanStart:span];
    [NSThread sleepForTimeInterval:0.01];
    NSDictionary<NSString *, NSNumber *> *attrs = [collector onSpanEnd:span];
    XCTAssertNotNil(attrs);

    BSG_TEST_LOG(@"Step 2: got %lu attributes (expected exactly 7): %@", (unsigned long)attrs.count, attrs);
    XCTAssertEqual(attrs.count, (NSUInteger)7);
    XCTAssertNotNil(attrs[BSGDiskIOAttributeKeyIOPSRead]);
    XCTAssertNotNil(attrs[BSGDiskIOAttributeKeyIOPSWrite]);
    XCTAssertNotNil(attrs[BSGDiskIOAttributeKeyIOPSTotal]);

    int64_t readStart = attrs[BSGDiskIODebugAttributeKeyReadStart].longLongValue;
    int64_t readEnd = attrs[BSGDiskIODebugAttributeKeyReadEnd].longLongValue;
    int64_t writeStart = attrs[BSGDiskIODebugAttributeKeyWriteStart].longLongValue;
    int64_t writeEnd = attrs[BSGDiskIODebugAttributeKeyWriteEnd].longLongValue;
    BSG_TEST_LOG(@"Step 3: read %lld->%lld write %lld->%lld (expecting start <= end)",
                 readStart, readEnd, writeStart, writeEnd);
    XCTAssertGreaterThanOrEqual(readStart, (int64_t)0);
    XCTAssertGreaterThanOrEqual(writeStart, (int64_t)0);
    XCTAssertLessThanOrEqual(readStart, readEnd);
    XCTAssertLessThanOrEqual(writeStart, writeEnd);
}

- (void)testSequentialSpansHaveMonotonicDebugSnapshots {
    // Two back-to-back spans: the second span's start counters must be >= the
    // first span's end counters - a stale or reused start snapshot would
    // violate this ordering.
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    collector.attachDebugSnapshots = YES;

    BSG_TEST_LOG(@"Step 1: run span 1 (start + sleep + end)");
    BugsnagPerformanceSpan *span1 = makeSpan();
    [collector onSpanStart:span1];
    [NSThread sleepForTimeInterval:0.01];
    NSDictionary<NSString *, NSNumber *> *attrs1 = [collector onSpanEnd:span1];
    XCTAssertNotNil(attrs1);

    BSG_TEST_LOG(@"Step 2: run span 2 strictly after span 1 has ended");
    BugsnagPerformanceSpan *span2 = makeSpan();
    [collector onSpanStart:span2];
    [NSThread sleepForTimeInterval:0.01];
    NSDictionary<NSString *, NSNumber *> *attrs2 = [collector onSpanEnd:span2];
    XCTAssertNotNil(attrs2);

    int64_t span1ReadEnd = attrs1[BSGDiskIODebugAttributeKeyReadEnd].longLongValue;
    int64_t span1WriteEnd = attrs1[BSGDiskIODebugAttributeKeyWriteEnd].longLongValue;
    int64_t span2ReadStart = attrs2[BSGDiskIODebugAttributeKeyReadStart].longLongValue;
    int64_t span2WriteStart = attrs2[BSGDiskIODebugAttributeKeyWriteStart].longLongValue;
    BSG_TEST_LOG(@"Step 3: span1 end read=%lld write=%lld, span2 start read=%lld write=%lld",
                 span1ReadEnd, span1WriteEnd, span2ReadStart, span2WriteStart);
    XCTAssertGreaterThanOrEqual(span2ReadStart, span1ReadEnd);
    XCTAssertGreaterThanOrEqual(span2WriteStart, span1WriteEnd);
}

- (void)testEndWithoutMatchingStartReturnsNil {
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    BugsnagPerformanceSpan *span = makeSpan();

    BSG_TEST_LOG(@"Step 1: calling onSpanEnd WITHOUT a prior onSpanStart");
    NSDictionary *attrs = [collector onSpanEnd:span];
    BSG_TEST_LOG(@"Step 2: got attrs=%@ (expected nil)", attrs);
    XCTAssertNil(attrs);
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)0);
}

- (void)testNilSpanIsIgnored {
    // The public API is annotated non-null, but the collector still guards
    // against nil defensively. Bypass the compile-time nullability check with
    // a runtime-typed variable so we can validate that defensive behavior.
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    BugsnagPerformanceSpan *nilSpan = nil;

    BSG_TEST_LOG(@"Step 1: calling onSpanStart with nil");
    [collector onSpanStart:nilSpan];
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)0);

    BSG_TEST_LOG(@"Step 2: calling onSpanEnd with nil (expecting nil result)");
    XCTAssertNil([collector onSpanEnd:nilSpan]);

    BSG_TEST_LOG(@"Step 3: calling abandonSpan with nil (should not crash)");
    [collector abandonSpan:nilSpan];
}

- (void)testAbandonReleasesPendingStart {
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    BugsnagPerformanceSpan *span = makeSpan();

    BSG_TEST_LOG(@"Step 1: onSpanStart");
    [collector onSpanStart:span];
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)1);

    BSG_TEST_LOG(@"Step 2: abandonSpan -- simulates cancellation");
    [collector abandonSpan:span];
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)0);

    // A subsequent onSpanEnd for the same span must return nil since the
    // start snapshot has been dropped.
    BSG_TEST_LOG(@"Step 3: onSpanEnd should now return nil");
    XCTAssertNil([collector onSpanEnd:span]);
}

- (void)testTwoSpansAreTrackedIndependently {
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    BugsnagPerformanceSpan *spanA = makeSpan();
    BugsnagPerformanceSpan *spanB = makeSpan();

    BSG_TEST_LOG(@"Step 1: onSpanStart for A (%016llx) and B (%016llx)",
                 (unsigned long long)spanA.spanId,
                 (unsigned long long)spanB.spanId);
    [collector onSpanStart:spanA];
    [collector onSpanStart:spanB];
    BSG_TEST_LOG(@"Step 2: pending=%lu (expected 2)", (unsigned long)collector.pendingSpanCount);
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)2);

    [NSThread sleepForTimeInterval:0.01];
    BSG_TEST_LOG(@"Step 3: onSpanEnd(A) -- B must remain pending");
    NSDictionary *attrsA = [collector onSpanEnd:spanA];
    XCTAssertNotNil(attrsA);
    BSG_TEST_LOG(@"Step 4: pending=%lu (expected 1)", (unsigned long)collector.pendingSpanCount);
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)1);

    BSG_TEST_LOG(@"Step 5: onSpanEnd(B)");
    NSDictionary *attrsB = [collector onSpanEnd:spanB];
    XCTAssertNotNil(attrsB);
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)0);
}

- (void)testConcurrentStartAndEndAreThreadSafe {
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    NSMutableArray<BugsnagPerformanceSpan *> *spans = [NSMutableArray array];
    const NSUInteger kSpanCount = 200;
    for (NSUInteger i = 0; i < kSpanCount; i++) {
        [spans addObject:makeSpan()];
    }
    BSG_TEST_LOG(@"Step 1: created %lu spans", (unsigned long)kSpanCount);

    dispatch_queue_t startQueue = dispatch_queue_create("bsg.diskio.tests.start", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t endQueue = dispatch_queue_create("bsg.diskio.tests.end", DISPATCH_QUEUE_CONCURRENT);

    dispatch_group_t group = dispatch_group_create();

    BSG_TEST_LOG(@"Step 2: dispatching %lu concurrent onSpanStart calls", (unsigned long)kSpanCount);
    for (BugsnagPerformanceSpan *span in spans) {
        dispatch_group_async(group, startQueue, ^{
            [collector onSpanStart:span];
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    BSG_TEST_LOG(@"Step 3: all starts done; pending=%lu", (unsigned long)collector.pendingSpanCount);
    // Ensure duration > 0.
    [NSThread sleepForTimeInterval:0.02];

    __block NSUInteger validEnds = 0;
    NSLock *counterLock = [NSLock new];
    BSG_TEST_LOG(@"Step 4: dispatching %lu concurrent onSpanEnd calls", (unsigned long)kSpanCount);
    for (BugsnagPerformanceSpan *span in spans) {
        dispatch_group_async(group, endQueue, ^{
            NSDictionary *attrs = [collector onSpanEnd:span];
            if (attrs != nil) {
                [counterLock lock];
                validEnds++;
                [counterLock unlock];
            }
        });
    }
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    BSG_TEST_LOG(@"Step 5: %lu / %lu ends produced valid attributes; final pending=%lu",
                 (unsigned long)validEnds,
                 (unsigned long)kSpanCount,
                 (unsigned long)collector.pendingSpanCount);

    XCTAssertEqual(validEnds, kSpanCount);
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)0);
}

#pragma mark - Test-only fault injection

// These guard the hook used by the Maze Runner disk IOPS scenarios. The most
// important assertion is the first one: production must always run with
// BSGDiskIOSnapshotFaultModeNone.

- (void)testFaultModeDefaultsToNone {
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    XCTAssertEqual(collector.faultMode, BSGDiskIOSnapshotFaultModeNone);
}

- (void)testFailAtStartFaultStoresNoStartSnapshotAndOmitsAttributes {
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    collector.faultMode = BSGDiskIOSnapshotFaultModeFailAtStart;
    BugsnagPerformanceSpan *span = makeSpan();

    [collector onSpanStart:span];
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)0);

    [NSThread sleepForTimeInterval:0.01];
    XCTAssertNil([collector onSpanEnd:span]);
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)0);
}

- (void)testFailAtEndFaultOmitsAttributesAndStillCleansUp {
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    collector.faultMode = BSGDiskIOSnapshotFaultModeFailAtEnd;
    BugsnagPerformanceSpan *span = makeSpan();

    [collector onSpanStart:span];
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)1);

    [NSThread sleepForTimeInterval:0.01];
    XCTAssertNil([collector onSpanEnd:span]);
    // The stored start snapshot must still be released.
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)0);
}

- (void)testZeroDurationFaultOmitsAttributes {
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    collector.faultMode = BSGDiskIOSnapshotFaultModeZeroDuration;
    BugsnagPerformanceSpan *span = makeSpan();

    [collector onSpanStart:span];
    [NSThread sleepForTimeInterval:0.01];
    XCTAssertNil([collector onSpanEnd:span]);
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)0);
}

// PLAT-17202 (Option B): a regressed counter omits the whole attribute set,
// matching the fail-at-start/fail-at-end/zero-duration paths above.
- (void)testNegativeDeltaFaultOmitsAttributes {
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    collector.faultMode = BSGDiskIOSnapshotFaultModeNegativeDelta;
    BugsnagPerformanceSpan *span = makeSpan();

    [collector onSpanStart:span];
    [NSThread sleepForTimeInterval:0.01];
    XCTAssertNil([collector onSpanEnd:span]);
    // The stored start snapshot must still be released.
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)0);
}

@end

#pragma mark - Lifecycle gating

// Asserts the SpanLifecycleHandlerImpl gating: disk IOPS attributes must never
// be collected or applied unless BugsnagPerformance has been started AND
// enabledMetrics.disk is on.
@interface DiskIOLifecycleGatingTests : XCTestCase
@end

@implementation DiskIOLifecycleGatingTests {
    BSGDiskIOCollector *collector_;
    std::shared_ptr<SpanLifecycleHandlerImpl> handler_;
}

- (void)setUpHandler {
    auto sampler = std::make_shared<Sampler>();
    auto spanStackingHandler = std::make_shared<SpanStackingHandler>();
    auto spanAttributesProvider = std::make_shared<SpanAttributesProvider>();
    collector_ = [BSGDiskIOCollector new];
    handler_ = std::make_shared<SpanLifecycleHandlerImpl>(
        sampler,
        std::make_shared<SpanStoreImpl>(spanStackingHandler),
        std::make_shared<ConditionTimeoutExecutor>(),
        std::make_shared<PlainSpanFactoryImpl>(sampler, spanStackingHandler, spanAttributesProvider),
        std::make_shared<Batch>(),
        [FrameMetricsCollector new],
        collector_,
        [BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> new],
        [BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> new],
        ^{},
        ^(BugsnagPerformanceSpan *) {},
        ^(BugsnagPerformanceSpan *) {});
}

- (BugsnagPerformanceConfiguration *)configWithDiskEnabled:(BOOL)diskEnabled {
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"12312312312312312312312312312312"];
    config.enabledMetrics.disk = diskEnabled;
    return config;
}

- (void)testNoDiskCollectionWhenNeverStarted {
    [self setUpHandler];
    // Even with disk metrics enabled in the configuration, nothing may be
    // collected before start() — this covers the pre-main/early-span window
    // and the "Bugsnag is never started" case.
    handler_->configure([self configWithDiskEnabled:YES]);

    BugsnagPerformanceSpan *span = makeSpan();
    handler_->onSpanStarted(span, SpanOptions());
    XCTAssertEqual(collector_.pendingSpanCount, (NSUInteger)0);

    [NSThread sleepForTimeInterval:0.01];
    handler_->onSpanEndSet(span);
    XCTAssertNil([span getAttribute:@"bugsnag.system.disk.iops_read"]);
    XCTAssertNil([span getAttribute:@"bugsnag.system.disk.iops_write"]);
    XCTAssertNil([span getAttribute:@"bugsnag.system.disk.iops_total"]);
}

- (void)testNoDiskCollectionWhenDiskMetricsDisabled {
    [self setUpHandler];
    // Default configuration: enabledMetrics.disk is NO.
    handler_->configure([self configWithDiskEnabled:NO]);
    handler_->start();

    BugsnagPerformanceSpan *span = makeSpan();
    handler_->onSpanStarted(span, SpanOptions());
    XCTAssertEqual(collector_.pendingSpanCount, (NSUInteger)0);

    [NSThread sleepForTimeInterval:0.01];
    handler_->onSpanEndSet(span);
    XCTAssertNil([span getAttribute:@"bugsnag.system.disk.iops_read"]);
    XCTAssertNil([span getAttribute:@"bugsnag.system.disk.iops_write"]);
    XCTAssertNil([span getAttribute:@"bugsnag.system.disk.iops_total"]);
}

- (void)testDiskCollectionWhenEnabledAndStarted {
    [self setUpHandler];
    handler_->configure([self configWithDiskEnabled:YES]);
    handler_->start();

    // makeSpan() creates a first-class span with metricsOptions.disk unset,
    // which is the eligible combination.
    BugsnagPerformanceSpan *span = makeSpan();
    handler_->onSpanStarted(span, SpanOptions());
    XCTAssertEqual(collector_.pendingSpanCount, (NSUInteger)1);

    [NSThread sleepForTimeInterval:0.01];
    handler_->onSpanEndSet(span);
    XCTAssertNotNil([span getAttribute:@"bugsnag.system.disk.iops_read"]);
    XCTAssertNotNil([span getAttribute:@"bugsnag.system.disk.iops_write"]);
    XCTAssertNotNil([span getAttribute:@"bugsnag.system.disk.iops_total"]);
    XCTAssertEqual(collector_.pendingSpanCount, (NSUInteger)0);
}

// Jira PLAT-17309 #21 (main-thread overhead): start and end 1,000
// disk-eligible spans in a tight loop on the main thread. Each span pays two
// snapshots (CFAbsoluteTimeGetCurrent + proc_pid_rusage), a mutex/map
// insert+erase, and the attribute write. The bound is deliberately generous
// (CI simulators are noisy) - the target from the checklist is < 10 us per
// snapshot; the measured figure is logged so regressions are visible.
- (void)testThousandSpansOnMainThreadStayCheap {
    XCTAssertTrue(NSThread.isMainThread);
    [self setUpHandler];
    handler_->configure([self configWithDiskEnabled:YES]);
    handler_->start();

    const int iterations = 1000;
    // Warm-up: first snapshot pays the one-time statfs()/NSTemporaryDirectory cost.
    {
        BugsnagPerformanceSpan *warm = makeSpan();
        handler_->onSpanStarted(warm, SpanOptions());
        handler_->onSpanEndSet(warm);
    }

    CFAbsoluteTime t0 = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < iterations; i++) {
        BugsnagPerformanceSpan *span = makeSpan();
        handler_->onSpanStarted(span, SpanOptions());
        handler_->onSpanEndSet(span);
    }
    CFAbsoluteTime elapsed = CFAbsoluteTimeGetCurrent() - t0;
    double perSpanMicros = elapsed / iterations * 1e6;
    BSG_TEST_LOG(@"%d start+end cycles on main thread: total=%.2fms, per span=%.2fus (2 snapshots each)",
                 iterations, elapsed * 1e3, perSpanMicros);

    XCTAssertEqual(collector_.pendingSpanCount, (NSUInteger)0, @"every start snapshot must be consumed");
    // 1,000 spans must complete well inside a single frame budget (16.7 ms);
    // 100 us per span (50 us per snapshot) is 5x the checklist target.
    XCTAssertLessThan(perSpanMicros, 100.0, @"disk-IO start+end costs %.2fus per span on the main thread", perSpanMicros);
}

@end


#pragma mark - App-session span across a background transition

#import "../../Sources/BugsnagPerformance/Private/AppStateTracker.h"
#import "../../Sources/BugsnagPerformance/Private/BugsnagPerformanceImpl.h"
#import "../../Sources/BugsnagPerformance/Private/BugsnagPerformanceConfiguration+Private.h"
#import "../../Sources/BugsnagPerformance/Private/Reachability.h"
#import "../../Sources/BugsnagPerformance/Private/EarlyConfiguration.h"
#import <UIKit/UIKit.h>

// Reproduces the e2e scenario "SDK captures disk IOPS across a mid-span
// background transition" at the SDK level: an app-session span is open when
// the app backgrounds, the app returns to the foreground, then the span ends.
// The span must survive the background abort, be accepted by the span-end
// callbacks, reach the export batch, and carry the three disk attributes.
@interface DiskIOAppSessionBackgroundTests : XCTestCase
@end

@implementation DiskIOAppSessionBackgroundTests

- (void)testAppSessionSpanSurvivesBackgroundTransitionAndReachesBatch {
    AppStateTracker *tracker = [AppStateTracker new];
    auto impl = std::make_unique<BugsnagPerformanceImpl>(std::make_shared<Reachability>(), tracker);
    impl->earlyConfigure([BSGEarlyConfiguration new]);
    impl->earlySetup();

    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"12312312312312312312312312312312"];
    config.endpoint = [NSURL URLWithString:@"http://127.0.0.1:9/traces"];
    config.autoInstrumentAppStarts = NO;
    config.autoInstrumentAppStartsLegacy = NO;
    config.autoInstrumentViewControllers = NO;
    config.autoInstrumentNetworkRequests = NO;
    config.samplingProbability = @1.0;
    config.enabledMetrics.disk = YES;
    // Keep the span in the batch so the test can observe it there.
    config.internal.autoTriggerExportOnBatchSize = 1000;
    config.internal.initialRecurringWorkDelay = 1000;
    __block BOOL endCallbackSawSessionSpan = NO;
    [config addOnSpanEndCallback:^BOOL(BugsnagPerformanceSpan *span) {
        if ([span.name isEqualToString:@"[AppSession/DiskIops]"]) {
            endCallbackSawSessionSpan = YES;
        }
        return YES;
    }];
    impl->configure(config);
    impl->preStartSetup();
    impl->start();

    BugsnagPerformanceSpan *span = impl->startAppSessionSpan(@"DiskIops");
    XCTAssertEqual(span.state, SpanStateOpen);
    BSG_TEST_LOG(@"Step 1: session span open, batch=%lu", (unsigned long)impl->testing_getBatchCount());

    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    [NSThread sleepForTimeInterval:0.2];
    BSG_TEST_LOG(@"Step 2: after background, span state=%d (0=open)", (int)span.state);
    XCTAssertEqual(span.state, SpanStateOpen, @"app-session span must survive backgrounding");

    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
    [NSThread sleepForTimeInterval:0.3];
    [span end];
    [NSThread sleepForTimeInterval:0.2];
    BSG_TEST_LOG(@"Step 3: after end, state=%d callback=%d batch=%lu attrs=%@",
                 (int)span.state, endCallbackSawSessionSpan,
                 (unsigned long)impl->testing_getBatchCount(),
                 [span getAttribute:@"bugsnag.system.disk.iops_total"]);

    XCTAssertEqual(span.state, SpanStateEnded);
    XCTAssertTrue(endCallbackSawSessionSpan, @"span-end callbacks must see the session span");
    XCTAssertEqual(impl->testing_getBatchCount(), (NSUInteger)1, @"session span must reach the export batch");
    XCTAssertNotNil([span getAttribute:@"bugsnag.system.disk.iops_read"]);
    XCTAssertNotNil([span getAttribute:@"bugsnag.system.disk.iops_write"]);
    XCTAssertNotNil([span getAttribute:@"bugsnag.system.disk.iops_total"]);
}

@end
