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

    // The start entry is kept until the span is final (a later end can
    // recompute); -abandonSpan: releases it.
    BSG_TEST_LOG(@"Step 7: pending after end=%lu (expected 1, released by abandon)", (unsigned long)collector.pendingSpanCount);
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)1);
    [collector abandonSpan:span];
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

- (void)testEndCanRunAgainUntilAbandoned {
    // The start snapshot survives an end so that a later end (a span
    // condition moving the end time) recomputes the metrics; only
    // -abandonSpan: drops it. Before this behaviour a second end returned nil.
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    BugsnagPerformanceSpan *span = makeSpan();
    [collector onSpanStart:span];
    [NSThread sleepForTimeInterval:0.01];

    XCTAssertNotNil([collector onSpanEnd:span], @"first end computes");
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)1);
    [NSThread sleepForTimeInterval:0.01];
    XCTAssertNotNil([collector onSpanEnd:span], @"second end must recompute, not find the start gone");
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)1);

    [collector abandonSpan:span];
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)0);
    XCTAssertNil([collector onSpanEnd:span], @"after abandon there is nothing to compute from");
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
    BSG_TEST_LOG(@"Step 3: onSpanEnd(A) then abandon(A) -- B must remain pending");
    NSDictionary *attrsA = [collector onSpanEnd:spanA];
    XCTAssertNotNil(attrsA);
    [collector abandonSpan:spanA];
    BSG_TEST_LOG(@"Step 4: pending=%lu (expected 1)", (unsigned long)collector.pendingSpanCount);
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)1);

    BSG_TEST_LOG(@"Step 5: onSpanEnd(B) then abandon(B)");
    NSDictionary *attrsB = [collector onSpanEnd:spanB];
    XCTAssertNotNil(attrsB);
    [collector abandonSpan:spanB];
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
            [collector abandonSpan:span];
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
    // The stored start snapshot is kept until the span is final, then released.
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)1);
    [collector abandonSpan:span];
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)0);
}

- (void)testZeroDurationFaultOmitsAttributes {
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    collector.faultMode = BSGDiskIOSnapshotFaultModeZeroDuration;
    BugsnagPerformanceSpan *span = makeSpan();

    [collector onSpanStart:span];
    [NSThread sleepForTimeInterval:0.01];
    XCTAssertNil([collector onSpanEnd:span]);
    [collector abandonSpan:span];
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
    [collector abandonSpan:span];
    XCTAssertEqual(collector.pendingSpanCount, (NSUInteger)0);
}

@end

#pragma mark - Lifecycle gating

// Asserts the SpanLifecycleHandlerImpl gating: disk IOPS attributes must never
// be collected or applied unless BugsnagPerformance has been started AND
// enabledMetrics.disk is on.
@interface DiskIOLifecycleGatingTests : XCTestCase
@end

// Shared fixture for the handler-level tests below: a SpanLifecycleHandlerImpl
// wired to a fresh collector, batch and span-end callback store.
struct DiskIOHandlerFixture {
    BSGDiskIOCollector *collector;
    std::shared_ptr<Batch> batch;
    BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> *spanEndCallbacks;
    std::shared_ptr<SpanLifecycleHandlerImpl> handler;
};

static DiskIOHandlerFixture makeHandlerFixture() {
    auto sampler = std::make_shared<Sampler>();
    auto spanStackingHandler = std::make_shared<SpanStackingHandler>();
    auto spanAttributesProvider = std::make_shared<SpanAttributesProvider>();
    DiskIOHandlerFixture f;
    f.collector = [BSGDiskIOCollector new];
    f.batch = std::make_shared<Batch>();
    f.spanEndCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> new];
    f.handler = std::make_shared<SpanLifecycleHandlerImpl>(
        sampler,
        std::make_shared<SpanStoreImpl>(spanStackingHandler),
        std::make_shared<ConditionTimeoutExecutor>(),
        std::make_shared<PlainSpanFactoryImpl>(sampler, spanStackingHandler, spanAttributesProvider),
        f.batch,
        [FrameMetricsCollector new],
        f.collector,
        [BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> new],
        f.spanEndCallbacks,
        ^{},
        ^(BugsnagPerformanceSpan *) {},
        ^(BugsnagPerformanceSpan *) {});
    return f;
}

static BugsnagPerformanceConfiguration *configWithDiskEnabled(BOOL diskEnabled) {
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"12312312312312312312312312312312"];
    config.enabledMetrics.disk = diskEnabled;
    return config;
}

@implementation DiskIOLifecycleGatingTests {
    BSGDiskIOCollector *collector_;
    std::shared_ptr<SpanLifecycleHandlerImpl> handler_;
}

- (void)setUpHandler {
    DiskIOHandlerFixture f = makeHandlerFixture();
    collector_ = f.collector;
    handler_ = f.handler;
}

- (void)testNoDiskCollectionWhenNeverStarted {
    [self setUpHandler];
    // Even with disk metrics enabled in the configuration, nothing may be
    // collected before start() — this covers the pre-main/early-span window
    // and the "Bugsnag is never started" case.
    handler_->configure(configWithDiskEnabled(YES));

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
    handler_->configure(configWithDiskEnabled(NO));
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
    handler_->configure(configWithDiskEnabled(YES));
    handler_->start();

    // makeSpan() creates a first-class span with metricsOptions.disk unset,
    // which is the eligible combination.
    BugsnagPerformanceSpan *span = makeSpan();
    handler_->onSpanStarted(span, SpanOptions());
    XCTAssertEqual(collector_.pendingSpanCount, (NSUInteger)1);

    [NSThread sleepForTimeInterval:0.01];
    [span end];
    handler_->onSpanEndSet(span);
    XCTAssertNotNil([span getAttribute:@"bugsnag.system.disk.iops_read"]);
    XCTAssertNotNil([span getAttribute:@"bugsnag.system.disk.iops_write"]);
    XCTAssertNotNil([span getAttribute:@"bugsnag.system.disk.iops_total"]);
    // The snapshot is held until the span is processed, then released.
    XCTAssertEqual(collector_.pendingSpanCount, (NSUInteger)1);
    handler_->onSpanClosed(span);
    XCTAssertEqual(collector_.pendingSpanCount, (NSUInteger)0);
}

- (void)testLaterEndRecomputesOverTheExtendedWindow {
    // A blocked span's end time can be moved later by a span condition, which
    // re-runs onSpanEndSet. The start snapshot must survive the first end so
    // the metrics are recomputed over the extended window, and be released
    // only when the span is finally processed.
    [self setUpHandler];
    handler_->configure(configWithDiskEnabled(YES));
    handler_->start();

    BugsnagPerformanceSpan *span = makeSpan();
    handler_->onSpanStarted(span, SpanOptions());
    [NSThread sleepForTimeInterval:0.01];
    [span end];
    handler_->onSpanEndSet(span);
    NSNumber *firstTotal = [span getAttribute:@"bugsnag.system.disk.iops_total"];
    XCTAssertNotNil(firstTotal);
    XCTAssertEqual(collector_.pendingSpanCount, (NSUInteger)1, @"start snapshot must survive the first end");

    // Condition extends the end time later: the end path runs again.
    [NSThread sleepForTimeInterval:0.05];
    handler_->onSpanEndSet(span);
    NSNumber *secondTotal = [span getAttribute:@"bugsnag.system.disk.iops_total"];
    XCTAssertNotNil(secondTotal, @"second end must recompute, not drop, the attributes");
    BSG_TEST_LOG(@"first total=%@ second total=%@ (recomputed over a longer window)", firstTotal, secondTotal);

    handler_->onSpanClosed(span);
    XCTAssertEqual(collector_.pendingSpanCount, (NSUInteger)0);
}

- (void)testNoDiskCollectionWhenStartTimeWasProvided {
    // Mirrors the rendering gate: a caller-supplied start time makes the real
    // elapsed window meaningless for the span, so no snapshot is taken.
    [self setUpHandler];
    handler_->configure(configWithDiskEnabled(YES));
    handler_->start();

    BugsnagPerformanceSpan *span = makeSpan();
    span.wasStartOrEndTimeProvided = YES;
    handler_->onSpanStarted(span, SpanOptions());
    XCTAssertEqual(collector_.pendingSpanCount, (NSUInteger)0);

    [NSThread sleepForTimeInterval:0.01];
    [span end];
    handler_->onSpanEndSet(span);
    handler_->onSpanClosed(span);
    XCTAssertNil([span getAttribute:@"bugsnag.system.disk.iops_total"]);
}

- (void)testNoDiskAttributesWhenEndTimeWasProvided {
    // A caller-supplied END time is only known at the end: the start snapshot
    // exists, but no attributes may be computed and the snapshot must still be
    // released when the span is processed.
    [self setUpHandler];
    handler_->configure(configWithDiskEnabled(YES));
    handler_->start();

    BugsnagPerformanceSpan *span = makeSpan();
    handler_->onSpanStarted(span, SpanOptions());
    XCTAssertEqual(collector_.pendingSpanCount, (NSUInteger)1);

    [NSThread sleepForTimeInterval:0.01];
    span.wasStartOrEndTimeProvided = YES;  // as endWithEndTime: does
    [span end];
    handler_->onSpanEndSet(span);
    XCTAssertNil([span getAttribute:@"bugsnag.system.disk.iops_total"]);
    handler_->onSpanClosed(span);
    XCTAssertEqual(collector_.pendingSpanCount, (NSUInteger)0, @"snapshot released even though no metrics were computed");
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
    handler_->configure(configWithDiskEnabled(YES));
    handler_->start();

    const int iterations = 1000;
    // Warm-up: the first snapshot pays the one-time dlsym lookup of proc_pid_rusage.
    {
        BugsnagPerformanceSpan *warm = makeSpan();
        handler_->onSpanStarted(warm, SpanOptions());
        [warm end];
        handler_->onSpanEndSet(warm);
        handler_->onSpanClosed(warm);
    }

    CFAbsoluteTime t0 = CFAbsoluteTimeGetCurrent();
    for (int i = 0; i < iterations; i++) {
        BugsnagPerformanceSpan *span = makeSpan();
        handler_->onSpanStarted(span, SpanOptions());
        [span end];
        handler_->onSpanEndSet(span);
        handler_->onSpanClosed(span);
    }
    CFAbsoluteTime elapsed = CFAbsoluteTimeGetCurrent() - t0;
    double perSpanMicros = elapsed / iterations * 1e6;
    BSG_TEST_LOG(@"%d start+end+close cycles on main thread: total=%.2fms, per span=%.2fus (2 snapshots each)",
                 iterations, elapsed * 1e3, perSpanMicros);

    XCTAssertEqual(collector_.pendingSpanCount, (NSUInteger)0, @"every start snapshot must be consumed");
    // 1,000 spans must complete well inside a single frame budget (16.7 ms);
    // 100 us per span (50 us per snapshot) is 5x the checklist target.
    XCTAssertLessThan(perSpanMicros, 100.0, @"disk-IO start+end costs %.2fus per span on the main thread", perSpanMicros);
}

@end


#pragma mark - App-session span across a background transition

// Reproduces the e2e scenario "SDK captures disk IOPS across a mid-span
// background transition" at the span-lifecycle level: an app-session span
// and an ordinary span are open when the app backgrounds. The ordinary span
// is aborted (abortOpenSpansOnBackground), the session span must survive,
// end normally, carry the three disk attributes and reach the export batch.
//
// Deliberately built on SpanLifecycleHandlerImpl rather than a started
// BugsnagPerformanceImpl: a started SDK instance has no shutdown path, so its
// sampler and worker keep running after the test destroys it and the next
// test dies on a destroyed mutex ("mutex lock failed: Invalid argument").
@interface DiskIOAppSessionBackgroundTests : XCTestCase
@end

@implementation DiskIOAppSessionBackgroundTests {
    BSGDiskIOCollector *collector_;
    std::shared_ptr<Batch> batch_;
    std::shared_ptr<SpanLifecycleHandlerImpl> handler_;
    BOOL endCallbackSawSessionSpan_;
}

- (void)setUp {
    DiskIOHandlerFixture f = makeHandlerFixture();
    collector_ = f.collector;
    batch_ = f.batch;
    handler_ = f.handler;
    endCallbackSawSessionSpan_ = NO;
    // A user on-span-end callback must observe the session span (and keep it).
    __weak DiskIOAppSessionBackgroundTests *weakSelf = self;
    [f.spanEndCallbacks addObject:^BOOL(BugsnagPerformanceSpan *span) {
        DiskIOAppSessionBackgroundTests *strongSelf = weakSelf;
        if (strongSelf != nil && span.isAppSessionSpan) {
            strongSelf->endCallbackSawSessionSpan_ = YES;
        }
        return YES;
    } priority:BugsnagPerformancePriorityMedium];
    handler_->configure(configWithDiskEnabled(YES));
    handler_->start();
}

- (void)testAppSessionSpanSurvivesBackgroundTransitionAndReachesBatch {
    BugsnagPerformanceSpan *session = makeSpan();
    session.isAppSessionSpan = YES;
    BugsnagPerformanceSpan *ordinary = makeSpan();

    handler_->onSpanStarted(session, SpanOptions());
    handler_->onSpanStarted(ordinary, SpanOptions());
    XCTAssertEqual(collector_.pendingSpanCount, (NSUInteger)2);
    BSG_TEST_LOG(@"Step 1: session + ordinary spans open, 2 start snapshots held");

    // The app goes to the background mid-span.
    handler_->onAppEnteredBackground();
    BSG_TEST_LOG(@"Step 2: after background: session state=%d ordinary state=%d",
                 (int)session.state, (int)ordinary.state);
    XCTAssertEqual(session.state, SpanStateOpen, @"app-session span must survive backgrounding");
    XCTAssertEqual(ordinary.state, SpanStateAborted, @"ordinary open span is aborted on background");
    // abortIfOpen reaches the handler through sendForProcessing -> the span's
    // onSpanClosed block (never onSpanCancelled). makeSpan() wires empty
    // blocks, so drive that production path by hand.
    handler_->onSpanClosed(ordinary);
    XCTAssertEqual(collector_.pendingSpanCount, (NSUInteger)1, @"aborted span must release its start snapshot");

    [NSThread sleepForTimeInterval:0.01];

    // The session span ends later (in the real scenario, from the background
    // handler or after foregrounding); follow the SDK's end sequence.
    [session end];
    handler_->onSpanEndSet(session);
    handler_->onSpanClosed(session);
    BSG_TEST_LOG(@"Step 3: after end: state=%d batch=%zu iops_total=%@",
                 (int)session.state, batch_->count(),
                 [session getAttribute:@"bugsnag.system.disk.iops_total"]);

    XCTAssertEqual(session.state, SpanStateEnded);
    XCTAssertTrue(endCallbackSawSessionSpan_, @"user span-end callbacks must see the session span");
    XCTAssertEqual(collector_.pendingSpanCount, (NSUInteger)0, @"every start snapshot must be consumed");
    XCTAssertEqual(batch_->count(), (size_t)1, @"session span must reach the export batch");
    XCTAssertNotNil([session getAttribute:@"bugsnag.system.disk.iops_read"]);
    XCTAssertNotNil([session getAttribute:@"bugsnag.system.disk.iops_write"]);
    XCTAssertNotNil([session getAttribute:@"bugsnag.system.disk.iops_total"]);
}

@end
