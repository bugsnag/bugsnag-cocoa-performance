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
    sampler->setProbability(1.0);
    auto batch = std::make_shared<Batch>();
    auto tracer = std::make_shared<Tracer>(stackingHandler, sampler, batch, ^(){});
    tracer->earlyConfigure(earlyConfig);
    tracer->earlySetup();
    tracer->configure(config);
    tracer->start();

    SpanOptions spanOptions;
    auto span = tracer->startViewLoadSpan(BugsnagPerformanceViewTypeUIKit, @"myclass", spanOptions);
    [span end];
    tracer->onPrewarmPhaseEnded();
    auto spans = batch->drain(true);
    XCTAssertEqual(spans->size(), 1UL);
}

- (void)testPrewarmEndAfter {
    auto earlyConfig = [BSGEarlyConfiguration new];
    earlyConfig.appWasLaunchedPreWarmed = YES;
    auto config = newConfig();
    auto stackingHandler = std::make_shared<SpanStackingHandler>();
    auto sampler = std::make_shared<Sampler>();
    sampler->setProbability(1.0);
    auto batch = std::make_shared<Batch>();
    auto tracer = std::make_shared<Tracer>(stackingHandler, sampler, batch, ^(){});
    tracer->earlyConfigure(earlyConfig);
    tracer->earlySetup();
    tracer->configure(config);
    tracer->start();

    SpanOptions spanOptions;
    auto span = tracer->startViewLoadSpan(BugsnagPerformanceViewTypeUIKit, @"myclass", spanOptions);
    tracer->onPrewarmPhaseEnded();
    [span end];
    auto spans = batch->drain(true);
    XCTAssertEqual(spans->size(), 0UL);
}

- (void)testNoPrewarmEndBefore {
    auto earlyConfig = [BSGEarlyConfiguration new];
    earlyConfig.appWasLaunchedPreWarmed = NO;
    auto config = newConfig();
    auto stackingHandler = std::make_shared<SpanStackingHandler>();
    auto sampler = std::make_shared<Sampler>();
    sampler->setProbability(1.0);
    auto batch = std::make_shared<Batch>();
    auto tracer = std::make_shared<Tracer>(stackingHandler, sampler, batch, ^(){});
    tracer->earlyConfigure(earlyConfig);
    tracer->earlySetup();
    tracer->configure(config);
    tracer->start();

    SpanOptions spanOptions;
    auto span = tracer->startViewLoadSpan(BugsnagPerformanceViewTypeUIKit, @"myclass", spanOptions);
    [span end];
    tracer->onPrewarmPhaseEnded();
    auto spans = batch->drain(true);
    XCTAssertEqual(spans->size(), 1UL);
}

- (void)testNoPrewarmEndAfter {
    auto earlyConfig = [BSGEarlyConfiguration new];
    earlyConfig.appWasLaunchedPreWarmed = NO;
    auto config = newConfig();
    auto stackingHandler = std::make_shared<SpanStackingHandler>();
    auto sampler = std::make_shared<Sampler>();
    sampler->setProbability(1.0);
    auto batch = std::make_shared<Batch>();
    auto tracer = std::make_shared<Tracer>(stackingHandler, sampler, batch, ^(){});
    tracer->earlyConfigure(earlyConfig);
    tracer->earlySetup();
    tracer->configure(config);
    tracer->start();

    SpanOptions spanOptions;
    auto span = tracer->startViewLoadSpan(BugsnagPerformanceViewTypeUIKit, @"myclass", spanOptions);
    tracer->onPrewarmPhaseEnded();
    [span end];
    auto spans = batch->drain(true);
    XCTAssertEqual(spans->size(), 1UL);
}

@end
