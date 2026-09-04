//
//  DiskIOCollectorTests.mm
//  BugsnagPerformance
//
//  Created by gaurav agarawal on 03/08/26.
//  Copyright © 2026 Bugsnag. All rights reserved.
//

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

- (void)testNegativeDeltaFaultClampsToZeroRatherThanEmittingInvalidValues {
    BSGDiskIOCollector *collector = [BSGDiskIOCollector new];
    collector.faultMode = BSGDiskIOSnapshotFaultModeNegativeDelta;
    BugsnagPerformanceSpan *span = makeSpan();

    [collector onSpanStart:span];
    [NSThread sleepForTimeInterval:0.01];
    NSDictionary<NSString *, NSNumber *> *attrs = [collector onSpanEnd:span];

    XCTAssertNotNil(attrs);
    XCTAssertEqual(attrs[@"bugsnag.system.disk.iops_read"].longLongValue, 0);
    XCTAssertEqual(attrs[@"bugsnag.system.disk.iops_write"].longLongValue, 0);
    XCTAssertEqual(attrs[@"bugsnag.system.disk.iops_total"].longLongValue, 0);
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

@end
