//
//  SpanLifecycleHandlerTests.mm
//  BugsnagPerformance
//
//  Created by Meiyalagan Ramadurai on 13/10/26.
//  Copyright © 2026 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <BugsnagPerformance/BugsnagPerformance.h>
#import "../../Sources/BugsnagPerformance/Private/SpanLifecycle/SpanLifecycleHandlerImpl.h"
#import "../../Sources/BugsnagPerformance/Private/SpanStore/SpanStoreImpl.h"
#import "../../Sources/BugsnagPerformance/Private/BugsnagPerformanceConfiguration+Private.h"
#import "BugsnagPerformanceSpan+Private.h"
#import "IdGenerator.h"
#import "SpanOptions.h"
#import <atomic>
#import <sched.h>
#import <memory>

using namespace bugsnag;

@interface SpanLifecycleHandlerTests : XCTestCase
@property (nonatomic, strong) BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> *onSpanStartCallbacks;
@property (nonatomic, strong) BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> *onSpanEndCallbacks;
@property (nonatomic, strong) FrameMetricsCollector *frameMetricsCollector;
@end

@implementation SpanLifecycleHandlerTests {
    std::shared_ptr<SpanLifecycleHandlerImpl> handler_;
    std::shared_ptr<Batch> batch_;
}

- (void)setUp {
    self.onSpanStartCallbacks = [BSGPrioritizedStore new];
    self.onSpanEndCallbacks = [BSGPrioritizedStore new];
    // A real collector always returns a non-nil snapshot, which lets us observe
    // whether rendering instrumentation was applied to a span.
    self.frameMetricsCollector = [FrameMetricsCollector new];

    batch_ = std::make_shared<Batch>();
    auto sampler = std::make_shared<Sampler>();
    auto stackingHandler = std::make_shared<SpanStackingHandler>();
    auto store = std::make_shared<SpanStoreImpl>(stackingHandler);
    auto plainSpanFactory = std::make_shared<PlainSpanFactoryImpl>(sampler,
                                                                    stackingHandler,
                                                                    std::make_shared<SpanAttributesProvider>());
    handler_ = std::make_shared<SpanLifecycleHandlerImpl>(sampler,
                                                          store,
                                                          std::make_shared<ConditionTimeoutExecutor>(),
                                                          plainSpanFactory,
                                                          batch_,
                                                          self.frameMetricsCollector,
                                                          self.onSpanStartCallbacks,
                                                          self.onSpanEndCallbacks,
                                                          ^{},
                                                          ^(BugsnagPerformanceSpan *) {},
                                                          ^(BugsnagPerformanceSpan *) {});
}

- (void)tearDown {
    handler_.reset();
    batch_.reset();
}

static BugsnagPerformanceSpan *createSpan(BSGTriState rendering) {
    MetricsOptions metricsOptions;
    metricsOptions.rendering = rendering;
    return [[BugsnagPerformanceSpan alloc] initWithName:@"test"
                                                traceId:IdGenerator::generateTraceId()
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

// A span whose end goes through the real handler path, exactly like production:
// [span end] -> onSpanEndSet -> sendForProcessing -> onSpanClosed -> processClosedSpan
//            -> forceMutate -> callOnSpanEndCallbacks
// (the stack in the customer's crash group 2). weak_ptr avoids a retain cycle
// through the Batch, which keeps ended spans.
static BugsnagPerformanceSpan *createWiredSpan(std::weak_ptr<SpanLifecycleHandlerImpl> weakHandler,
                                               BSGTriState rendering) {
    MetricsOptions metricsOptions;
    metricsOptions.rendering = rendering;
    return [[BugsnagPerformanceSpan alloc] initWithName:@"test"
                                                traceId:IdGenerator::generateTraceId()
                                                 spanId:IdGenerator::generateSpanId()
                                               parentId:IdGenerator::generateSpanId()
                                              startTime:SpanOptions().startTime
                                             firstClass:BSGTriStateYes
                                    samplingProbability:1.0
                                    attributeCountLimit:128
                                         metricsOptions:metricsOptions
                                 conditionsToEndOnClose:@[]
                                           onSpanEndSet:^(BugsnagPerformanceSpan * _Nonnull span) {
        if (auto handler = weakHandler.lock()) {
            handler->onSpanEndSet(span);
        }
    }
                                           onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull span) {
        if (auto handler = weakHandler.lock()) {
            handler->onSpanClosed(span);
        }
    }
                                          onSpanBlocked:^BugsnagPerformanceSpanCondition * _Nullable(BugsnagPerformanceSpan * _Nonnull, NSTimeInterval) { return nil; }
                                        onSpanCancelled:^(BugsnagPerformanceSpan * _Nonnull) {}];
}

static SpanOptions spanOptions() {
    SpanOptions options;
    // Keep the span stack out of these tests; it is not what we're exercising.
    options.makeCurrentContext = false;
    return options;
}

static BugsnagPerformanceConfiguration *configWithRendering(BOOL rendering) {
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"0123456789abcdef0123456789abcdef"];
    config.enabledMetrics.rendering = rendering;
    return config;
}

#pragma mark - Rendering metrics behaviour (must be unchanged by the fix)

- (void)testRenderingIsEnabledBeforeConfigure {
    // Matches the previous default of [BugsnagPerformanceEnabledMetrics withAllEnabled]
    auto span = createSpan(BSGTriStateYes);
    handler_->onSpanStarted(span, spanOptions());
    XCTAssertNotNil(span.startFramerateSnapshot);
}

- (void)testConfigureWithRenderingDisabledSkipsFrameMetrics {
    handler_->configure(configWithRendering(NO));

    auto span = createSpan(BSGTriStateYes);
    handler_->onSpanStarted(span, spanOptions());
    XCTAssertNil(span.startFramerateSnapshot);
}

- (void)testConfigureWithRenderingEnabledCapturesFrameMetrics {
    handler_->configure(configWithRendering(YES));

    auto span = createSpan(BSGTriStateYes);
    handler_->onSpanStarted(span, spanOptions());
    XCTAssertNotNil(span.startFramerateSnapshot);
}

- (void)testUnsetSpanRenderingOptionFollowsConfigForFirstClassSpans {
    handler_->configure(configWithRendering(YES));
    auto enabledSpan = createSpan(BSGTriStateUnset);
    handler_->onSpanStarted(enabledSpan, spanOptions());
    XCTAssertNotNil(enabledSpan.startFramerateSnapshot);

    handler_->configure(configWithRendering(NO));
    auto disabledSpan = createSpan(BSGTriStateUnset);
    handler_->onSpanStarted(disabledSpan, spanOptions());
    XCTAssertNil(disabledSpan.startFramerateSnapshot);
}

- (void)testSpanOptingOutOfRenderingIsRespected {
    handler_->configure(configWithRendering(YES));

    auto span = createSpan(BSGTriStateNo);
    handler_->onSpanStarted(span, spanOptions());
    XCTAssertNil(span.startFramerateSnapshot);
}

- (void)testOnSpanStartCallbacksAreCalled {
    __block int calls = 0;
    [self.onSpanStartCallbacks addObject:^(BugsnagPerformanceSpan *) { calls++; }
                                priority:BugsnagPerformancePriorityMedium];

    handler_->onSpanStarted(createSpan(BSGTriStateNo), spanOptions());
    XCTAssertEqual(calls, 1);
}

- (void)testOnSpanEndCallbacksAreCalledWhenSpanEnds {
    __block int calls = 0;
    [self.onSpanEndCallbacks addObject:^BOOL(BugsnagPerformanceSpan *) { calls++; return YES; }
                              priority:BugsnagPerformancePriorityMedium];

    auto span = createWiredSpan(handler_, BSGTriStateNo);
    handler_->onSpanStarted(span, spanOptions());
    [span end];

    XCTAssertEqual(calls, 1);
    XCTAssertEqual(span.state, SpanStateEnded);
}

- (void)testOnSpanEndCallbackReturningNoDiscardsSpan {
    [self.onSpanEndCallbacks addObject:^BOOL(BugsnagPerformanceSpan *) { return NO; }
                              priority:BugsnagPerformancePriorityMedium];

    auto span = createWiredSpan(handler_, BSGTriStateNo);
    handler_->onSpanStarted(span, spanOptions());
    [span end];

    XCTAssertEqual(span.state, SpanStateAborted);
}

- (void)testRenderingDisabledSkipsEndFrameMetrics {
    handler_->configure(configWithRendering(NO));

    auto span = createWiredSpan(handler_, BSGTriStateYes);
    handler_->onSpanStarted(span, spanOptions());
    [span end];

    XCTAssertNil(span.startFramerateSnapshot);
    XCTAssertNil(span.endFramerateSnapshot);
}

- (void)testRenderingEnabledCapturesEndFrameMetrics {
    handler_->configure(configWithRendering(YES));

    auto span = createWiredSpan(handler_, BSGTriStateYes);
    handler_->onSpanStarted(span, spanOptions());
    [span end];

    XCTAssertNotNil(span.startFramerateSnapshot);
    XCTAssertNotNil(span.endFramerateSnapshot);
}

#pragma mark - Thread safety (regression for EXC_BAD_ACCESS, Zendesk #78933)

// Safety cap on spans per worker so time and memory stay bounded on slow CI
// simulators. Workers normally stop earlier, as soon as configure() finishes.
static const int kMaxSpansPerWorker = 5000;

// Runs the configure()-vs-span race used by the tests below.
//
// - Every worker and the configure loop run on their own NSThread, not the GCD
//   pool, so all of them are guaranteed to be scheduled.
// - Workers check in and then wait for a shared "go" flag. configure() starts
//   only after every worker has checked in (asserted, not a silent timeout), so
//   the race always overlaps and the test can't pass without exercising it.
// - Each worker runs until configure() finishes, or kMaxSpansPerWorker.
//
// Returns the total number of span steps executed.
- (int)runConfigureRaceWithSpanThreads:(int)spanThreads
                   configureIterations:(int)configureIterations
                         configureStep:(void (^)(int iteration))configureStep
                              spanStep:(void (^)(void))spanStep {
    auto go = std::make_shared<std::atomic<bool>>(false);
    auto configureFinished = std::make_shared<std::atomic<bool>>(false);
    auto spanSteps = std::make_shared<std::atomic<int>>(0);
    dispatch_semaphore_t workersReady = dispatch_semaphore_create(0);
    dispatch_group_t group = dispatch_group_create();

    for (int t = 0; t < spanThreads; t++) {
        dispatch_group_enter(group);
        [NSThread detachNewThreadWithBlock:^{
            dispatch_semaphore_signal(workersReady);  // check in
            while (!go->load()) {
                sched_yield();
            }
            int count = 0;
            do {
                @autoreleasepool {
                    spanStep();
                }
                (*spanSteps)++;
            } while (!configureFinished->load() && ++count < kMaxSpansPerWorker);
            dispatch_group_leave(group);
        }];
    }

    // Every worker must be running before configure() starts; otherwise the
    // test would pass without exercising the race.
    for (int t = 0; t < spanThreads; t++) {
        long waitResult = dispatch_semaphore_wait(workersReady,
                                                  dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
        XCTAssertEqual(waitResult, 0, @"A span worker thread never started");
    }

    // "configure" thread
    dispatch_group_enter(group);
    [NSThread detachNewThreadWithBlock:^{
        go->store(true);
        for (int i = 0; i < configureIterations; i++) {
            configureStep(i);
        }
        configureFinished->store(true);
        dispatch_group_leave(group);
    }];

    long result = dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC));
    XCTAssertEqual(result, 0, @"Concurrent configure/span work did not finish in time");
    return spanSteps->load();
}

// Reproduces the customer scenario: spans start on several threads while
// BugsnagPerformance.start(configuration:) runs configure() on another thread,
// which swaps the rendering setting and adds on-span-start callbacks.
// Before the fix this could crash with EXC_BAD_ACCESS; run with Address
// Sanitizer or Thread Sanitizer for a deterministic signal.
- (void)testConfigureConcurrentWithSpanStartDoesNotCrash {
    const int configureIterations = 500;
    auto callbackCalls = std::make_shared<std::atomic<int>>(0);
    auto handler = handler_;
    auto startCallbacks = self.onSpanStartCallbacks;

    int spansStarted = [self runConfigureRaceWithSpanThreads:4
                                         configureIterations:configureIterations
                                               configureStep:^(int i) {
        handler->configure(configWithRendering(i % 2 == 0));
        // Each add replaces the store's objects array, as configure()
        // does via BSGPluginManager when callbacks are configured.
        [startCallbacks addObject:^(BugsnagPerformanceSpan *) { (*callbackCalls)++; }
                         priority:BugsnagPerformancePriorityMedium];
    } spanStep:^{
        handler->onSpanStarted(createSpan(BSGTriStateUnset), spanOptions());
    }];

    XCTAssertGreaterThan(spansStarted, 0);
    XCTAssertEqual(startCallbacks.objects.count, (NSUInteger)configureIterations);

    // After the race, every configured callback must be invoked for a new span.
    callbackCalls->store(0);
    handler->onSpanStarted(createSpan(BSGTriStateNo), spanOptions());
    XCTAssertEqual(callbackCalls->load(), configureIterations);
}

// Matches the customer's reproduced crash (group 2): spans END on several threads
// while configure() adds on-span-end callbacks (replacing the callbacks array)
// and replaces the rendering setting (group 1). Spans are started and ended
// through the real span -> handler path.
- (void)testConfigureConcurrentWithSpanEndDoesNotCrash {
    const int configureIterations = 500;
    auto endCallbackCalls = std::make_shared<std::atomic<int>>(0);
    auto endedSinceDrain = std::make_shared<std::atomic<int>>(0);
    auto handler = handler_;
    auto batch = batch_;
    std::weak_ptr<SpanLifecycleHandlerImpl> weakHandler = handler_;
    auto endCallbacks = self.onSpanEndCallbacks;

    int spansEnded = [self runConfigureRaceWithSpanThreads:6
                                       configureIterations:configureIterations
                                             configureStep:^(int i) {
        handler->configure(configWithRendering(i % 2 == 0));
        [endCallbacks addObject:^BOOL(BugsnagPerformanceSpan *) { (*endCallbackCalls)++; return YES; }
                       priority:BugsnagPerformancePriorityMedium];
    } spanStep:^{
        auto span = createWiredSpan(weakHandler, BSGTriStateUnset);
        handler->onSpanStarted(span, spanOptions());
        [span end];
        // The Batch keeps every ended span; drain it now and then so memory
        // stays flat however long the race runs.
        if (++(*endedSinceDrain) % 500 == 0) {
            batch->drain(true);
        }
    }];

    XCTAssertGreaterThan(spansEnded, 0);
    XCTAssertEqual(endCallbacks.objects.count, (NSUInteger)configureIterations);

    // After the race, every configured end callback must run for a new span.
    endCallbackCalls->store(0);
    auto span = createWiredSpan(weakHandler, BSGTriStateNo);
    handler->onSpanStarted(span, spanOptions());
    [span end];
    XCTAssertEqual(endCallbackCalls->load(), configureIterations);
    XCTAssertEqual(span.state, SpanStateEnded);
}

@end

