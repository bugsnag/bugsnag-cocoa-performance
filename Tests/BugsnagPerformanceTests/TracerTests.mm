//
//  TracerTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 18.10.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Tracer.h"

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
    XCTAssertTrue([[span getAttribute:@"bugsnag.span.category"] isEqualToString: @"network"]);
    XCTAssertEqualObjects(span.name, @"[HTTP/GET]");
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

@end
