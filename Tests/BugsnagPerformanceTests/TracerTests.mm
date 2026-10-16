//
//  TracerTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 18.10.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Tracer.h"
#import <atomic>
#import <memory>
#import <sched.h>

using namespace bugsnag;

@interface TracerTests : XCTestCase

@end

static BugsnagPerformanceConfiguration *newConfig() {
    return [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"];
}

@implementation TracerTests

- (void)testPrewarmEndBefore {
    auto earlyConfig = [BSGEarlyConfiguration new];
    earlyConfig.appWasLaunchedPreWarmed = YES;
    auto config = newConfig();
    auto stackingHandler = std::make_shared<SpanStackingHandler>();
    auto sampler = std::make_shared<Sampler>();
    auto frameMetricsCollector = [FrameMetricsCollector new];
    auto conditionTimeoutExecutor = std::make_shared<ConditionTimeoutExecutor>();
    auto spanAttributesProvider = std::make_shared<SpanAttributesProvider>();
    sampler->setProbability(1.0);
    auto batch = std::make_shared<Batch>();
    auto spanStartCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> new];
    auto spanEndCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> new];
    auto tracer = std::make_shared<Tracer>(stackingHandler, sampler, batch, frameMetricsCollector, conditionTimeoutExecutor, spanAttributesProvider, spanStartCallbacks, spanEndCallbacks, ^(){});
    tracer->earlyConfigure(earlyConfig);
    tracer->earlySetup();
    tracer->configure(config);
    tracer->start();

    SpanOptions spanOptions;
    auto span = tracer->startViewLoadSpan(BugsnagPerformanceViewTypeUIKit, @"myclass", spanOptions);
    [span end];
    tracer->onPrewarmPhaseEnded();
    auto spans = batch->drain(true);
    XCTAssertEqual(spans.count, 1UL);
}

- (void)testPrewarmEndAfter {
    auto earlyConfig = [BSGEarlyConfiguration new];
    earlyConfig.appWasLaunchedPreWarmed = YES;
    auto config = newConfig();
    auto stackingHandler = std::make_shared<SpanStackingHandler>();
    auto sampler = std::make_shared<Sampler>();
    sampler->setProbability(1.0);
    auto batch = std::make_shared<Batch>();
    auto frameMetricsCollector = [FrameMetricsCollector new];
    auto conditionTimeoutExecutor = std::make_shared<ConditionTimeoutExecutor>();
    auto spanAttributesProvider = std::make_shared<SpanAttributesProvider>();
    auto spanStartCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> new];
    auto spanEndCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> new];
    auto tracer = std::make_shared<Tracer>(stackingHandler, sampler, batch, frameMetricsCollector, conditionTimeoutExecutor, spanAttributesProvider, spanStartCallbacks, spanEndCallbacks, ^(){});
    tracer->earlyConfigure(earlyConfig);
    tracer->earlySetup();
    tracer->configure(config);
    tracer->start();

    SpanOptions spanOptions;
    auto span = tracer->startViewLoadSpan(BugsnagPerformanceViewTypeUIKit, @"myclass", spanOptions);
    tracer->onPrewarmPhaseEnded();
    [span end];
    auto spans = batch->drain(true);
    XCTAssertEqual(spans.count, 0UL);
}

- (void)testNoPrewarmEndBefore {
    auto earlyConfig = [BSGEarlyConfiguration new];
    earlyConfig.appWasLaunchedPreWarmed = NO;
    auto config = newConfig();
    auto stackingHandler = std::make_shared<SpanStackingHandler>();
    auto sampler = std::make_shared<Sampler>();
    sampler->setProbability(1.0);
    auto batch = std::make_shared<Batch>();
    auto frameMetricsCollector = [FrameMetricsCollector new];
    auto conditionTimeoutExecutor = std::make_shared<ConditionTimeoutExecutor>();
    auto spanAttributesProvider = std::make_shared<SpanAttributesProvider>();
    auto spanStartCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> new];
    auto spanEndCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> new];
    auto tracer = std::make_shared<Tracer>(stackingHandler, sampler, batch, frameMetricsCollector, conditionTimeoutExecutor, spanAttributesProvider, spanStartCallbacks, spanEndCallbacks, ^(){});
    tracer->earlyConfigure(earlyConfig);
    tracer->earlySetup();
    tracer->configure(config);
    tracer->start();

    SpanOptions spanOptions;
    auto span = tracer->startViewLoadSpan(BugsnagPerformanceViewTypeUIKit, @"myclass", spanOptions);
    [span end];
    tracer->onPrewarmPhaseEnded();
    auto spans = batch->drain(true);
    XCTAssertEqual(spans.count, 1UL);
}

- (void)testNoPrewarmEndAfter {
    auto earlyConfig = [BSGEarlyConfiguration new];
    earlyConfig.appWasLaunchedPreWarmed = NO;
    auto config = newConfig();
    auto stackingHandler = std::make_shared<SpanStackingHandler>();
    auto sampler = std::make_shared<Sampler>();
    sampler->setProbability(1.0);
    auto batch = std::make_shared<Batch>();
    auto frameMetricsCollector = [FrameMetricsCollector new];
    auto conditionTimeoutExecutor = std::make_shared<ConditionTimeoutExecutor>();
    auto spanAttributesProvider = std::make_shared<SpanAttributesProvider>();
    auto spanStartCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> new];
    auto spanEndCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> new];
    auto tracer = std::make_shared<Tracer>(stackingHandler, sampler, batch, frameMetricsCollector, conditionTimeoutExecutor, spanAttributesProvider, spanStartCallbacks, spanEndCallbacks, ^(){});
    tracer->earlyConfigure(earlyConfig);
    tracer->earlySetup();
    tracer->configure(config);
    tracer->start();

    SpanOptions spanOptions;
    auto span = tracer->startViewLoadSpan(BugsnagPerformanceViewTypeUIKit, @"myclass", spanOptions);
    tracer->onPrewarmPhaseEnded();
    [span end];
    auto spans = batch->drain(true);
    XCTAssertEqual(spans.count, 1UL);
}

- (void)testNetworkSpan {
    auto stackingHandler = std::make_shared<SpanStackingHandler>();
    auto sampler = std::make_shared<Sampler>();
    sampler->setProbability(1.0);
    auto batch = std::make_shared<Batch>();
    auto frameMetricsCollector = [FrameMetricsCollector new];
    auto conditionTimeoutExecutor = std::make_shared<ConditionTimeoutExecutor>();
    auto spanAttributesProvider = std::make_shared<SpanAttributesProvider>();
    auto spanStartCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> new];
    auto spanEndCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> new];
    auto tracer = std::make_shared<Tracer>(stackingHandler, sampler, batch, frameMetricsCollector, conditionTimeoutExecutor, spanAttributesProvider, spanStartCallbacks, spanEndCallbacks, ^(){});
    SpanOptions spanOptions;
    auto span = tracer->startNetworkSpan(@"GET", spanOptions);
    XCTAssertEqual(span.kind, SPAN_KIND_CLIENT);
    XCTAssertEqualObjects([span getAttribute:@"bugsnag.span.category"], @"network");
    XCTAssertEqualObjects(span.name, @"[HTTP/GET]");
}

- (void)testNetworkSpanWithUnknownMethod {
    auto stackingHandler = std::make_shared<SpanStackingHandler>();
    auto sampler = std::make_shared<Sampler>();
    sampler->setProbability(1.0);
    auto batch = std::make_shared<Batch>();
    auto frameMetricsCollector = [FrameMetricsCollector new];
    auto conditionTimeoutExecutor = std::make_shared<ConditionTimeoutExecutor>();
    auto spanAttributesProvider = std::make_shared<SpanAttributesProvider>();
    auto spanStartCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> new];
    auto spanEndCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> new];
    auto tracer = std::make_shared<Tracer>(stackingHandler, sampler, batch, frameMetricsCollector, conditionTimeoutExecutor, spanAttributesProvider, spanStartCallbacks, spanEndCallbacks, ^(){});
    SpanOptions spanOptions;
    auto span = tracer->startNetworkSpan(nil, spanOptions);
    XCTAssertEqual(span.kind, SPAN_KIND_CLIENT);
    XCTAssertEqualObjects([span getAttribute:@"bugsnag.span.category"], @"network");
    XCTAssertEqualObjects(span.name, @"[HTTP/unknown]");
}

- (void)testStartSpan {
    auto expectedSamplingProbability = 0.4;
    auto stackingHandler = std::make_shared<SpanStackingHandler>();
    auto sampler = std::make_shared<Sampler>();
    sampler->setProbability(expectedSamplingProbability);
    auto batch = std::make_shared<Batch>();
    auto frameMetricsCollector = [FrameMetricsCollector new];
    auto conditionTimeoutExecutor = std::make_shared<ConditionTimeoutExecutor>();
    auto spanAttributesProvider = std::make_shared<SpanAttributesProvider>();
    auto spanStartCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> new];
    auto spanEndCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> new];
    auto tracer = std::make_shared<Tracer>(stackingHandler, sampler, batch, frameMetricsCollector, conditionTimeoutExecutor, spanAttributesProvider, spanStartCallbacks, spanEndCallbacks, ^(){});
    SpanOptions spanOptions;
    auto span = tracer->startSpan(@"TestSpan", spanOptions, BSGTriStateYes);
    XCTAssertEqual(span.kind, SPAN_KIND_INTERNAL);
    XCTAssertEqualObjects(span.name, @"TestSpan");
    XCTAssertEqual(span.samplingProbability, expectedSamplingProbability);
}

#pragma mark - Thread safety

// Safety cap on spans per worker so time and memory stay bounded on slow CI
// simulators. Workers normally stop earlier, as soon as configure() finishes.
static const int kMaxSpansPerWorker = 5000;

static std::shared_ptr<Tracer> newStartedTracer(std::shared_ptr<Batch> batch,
                                                BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> *spanStartCallbacks,
                                                BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> *spanEndCallbacks) {
    auto sampler = std::make_shared<Sampler>();
    sampler->setProbability(1.0);
    auto tracer = std::make_shared<Tracer>(std::make_shared<SpanStackingHandler>(),
                                           sampler,
                                           batch,
                                           [FrameMetricsCollector new],
                                           std::make_shared<ConditionTimeoutExecutor>(),
                                           std::make_shared<SpanAttributesProvider>(),
                                           spanStartCallbacks,
                                           spanEndCallbacks,
                                           ^(){});
    tracer->earlyConfigure([BSGEarlyConfiguration new]);
    tracer->earlySetup();
    tracer->configure(newConfig());
    tracer->start();
    return tracer;
}

static BugsnagPerformanceConfiguration *configWithRendering(BOOL rendering) {
    auto config = newConfig();
    config.enabledMetrics.rendering = rendering;
    return config;
}

static SpanOptions raceSpanOptions() {
    SpanOptions options;
    // Keep the span stack out of these tests; it is not what we're exercising.
    options.makeCurrentContext = false;
    return options;
}

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

// Customer scenario: spans start on several threads while
// BugsnagPerformance.start(configuration:) runs configure() on another thread,
// which swaps the rendering setting and adds on-span-start callbacks.
// Before the fix this could crash with EXC_BAD_ACCESS; run with Thread
// Sanitizer or Address Sanitizer for a deterministic signal.
- (void)testConfigureConcurrentWithSpanStartDoesNotCrash {
    const int configureIterations = 500;
    auto callbackCalls = std::make_shared<std::atomic<int>>(0);
    auto batch = std::make_shared<Batch>();
    auto startCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> new];
    auto endCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> new];
    auto tracer = newStartedTracer(batch, startCallbacks, endCallbacks);

    int spansStarted = [self runConfigureRaceWithSpanThreads:4
                                         configureIterations:configureIterations
                                               configureStep:^(int i) {
        tracer->configure(configWithRendering(i % 2 == 0));
        // Each add replaces the store's objects array, as configure()
        // does via BSGPluginManager when callbacks are configured.
        [startCallbacks addObject:^(BugsnagPerformanceSpan *) { (*callbackCalls)++; }
                         priority:BugsnagPerformancePriorityMedium];
    } spanStep:^{
        tracer->startSpan(@"race", raceSpanOptions(), BSGTriStateYes);
    }];

    XCTAssertGreaterThan(spansStarted, 0);
    XCTAssertEqual(startCallbacks.objects.count, (NSUInteger)configureIterations);

    // After the race, every configured callback must be invoked for a new span.
    // End it inside a pool so it is released while the tracer is still alive.
    callbackCalls->store(0);
    @autoreleasepool {
        auto span = tracer->startSpan(@"after", raceSpanOptions(), BSGTriStateYes);
        XCTAssertEqual(callbackCalls->load(), configureIterations);
        [span end];
    }
}

// Customer crash group 2: spans END on several threads while configure() adds
// on-span-end callbacks (replacing the callbacks array) and replaces the
// rendering setting. Spans are started and ended through the real Tracer path.
- (void)testConfigureConcurrentWithSpanEndDoesNotCrash {
    const int configureIterations = 500;
    auto endCallbackCalls = std::make_shared<std::atomic<int>>(0);
    auto endedSinceDrain = std::make_shared<std::atomic<int>>(0);
    auto batch = std::make_shared<Batch>();
    auto startCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> new];
    auto endCallbacks = [BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> new];
    auto tracer = newStartedTracer(batch, startCallbacks, endCallbacks);

    int spansEnded = [self runConfigureRaceWithSpanThreads:6
                                       configureIterations:configureIterations
                                             configureStep:^(int i) {
        tracer->configure(configWithRendering(i % 2 == 0));
        [endCallbacks addObject:^BOOL(BugsnagPerformanceSpan *) { (*endCallbackCalls)++; return YES; }
                       priority:BugsnagPerformancePriorityMedium];
    } spanStep:^{
        auto span = tracer->startSpan(@"race", raceSpanOptions(), BSGTriStateYes);
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
    @autoreleasepool {
        auto span = tracer->startSpan(@"after", raceSpanOptions(), BSGTriStateYes);
        [span end];
        XCTAssertEqual(endCallbackCalls->load(), configureIterations);
        XCTAssertEqual(span.state, SpanStateEnded);
    }
}

@end
