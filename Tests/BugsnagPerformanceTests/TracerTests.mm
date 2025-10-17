//
//  TracerTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 18.10.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Tracer.h"
#import "AppStartupSpanFactoryImpl.h"
#import "ViewLoadSpanFactoryImpl.h"
#import "NetworkSpanFactoryImpl.h"

using namespace bugsnag;

@interface TracerTests : XCTestCase

@end

@implementation TracerTests

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
    
    auto plainSpanFactory = std::make_shared<PlainSpanFactoryImpl>(sampler, stackingHandler, spanAttributesProvider);
    auto appStartupSpanFactory = std::make_shared<AppStartupSpanFactoryImpl>(plainSpanFactory, spanAttributesProvider);
    auto viewLoadSpanFactory = std::make_shared<ViewLoadSpanFactoryImpl>(plainSpanFactory, spanAttributesProvider);
    auto networkSpanFactory = std::make_shared<NetworkSpanFactoryImpl>(plainSpanFactory, spanAttributesProvider);
    
    auto tracer = std::make_shared<Tracer>(stackingHandler,
                                           sampler,
                                           batch,
                                           frameMetricsCollector,
                                           conditionTimeoutExecutor,
                                           plainSpanFactory,
                                           viewLoadSpanFactory,
                                           networkSpanFactory,
                                           spanStartCallbacks,
                                           spanEndCallbacks,
                                           ^(){});
    
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
    
    auto plainSpanFactory = std::make_shared<PlainSpanFactoryImpl>(sampler, stackingHandler, spanAttributesProvider);
    auto appStartupSpanFactory = std::make_shared<AppStartupSpanFactoryImpl>(plainSpanFactory, spanAttributesProvider);
    auto viewLoadSpanFactory = std::make_shared<ViewLoadSpanFactoryImpl>(plainSpanFactory, spanAttributesProvider);
    auto networkSpanFactory = std::make_shared<NetworkSpanFactoryImpl>(plainSpanFactory, spanAttributesProvider);
    
    auto tracer = std::make_shared<Tracer>(stackingHandler,
                                           sampler,
                                           batch,
                                           frameMetricsCollector,
                                           conditionTimeoutExecutor,
                                           plainSpanFactory,
                                           viewLoadSpanFactory,
                                           networkSpanFactory,
                                           spanStartCallbacks,
                                           spanEndCallbacks,
                                           ^(){});
    
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
    
    auto plainSpanFactory = std::make_shared<PlainSpanFactoryImpl>(sampler, stackingHandler, spanAttributesProvider);
    auto appStartupSpanFactory = std::make_shared<AppStartupSpanFactoryImpl>(plainSpanFactory, spanAttributesProvider);
    auto viewLoadSpanFactory = std::make_shared<ViewLoadSpanFactoryImpl>(plainSpanFactory, spanAttributesProvider);
    auto networkSpanFactory = std::make_shared<NetworkSpanFactoryImpl>(plainSpanFactory, spanAttributesProvider);
    
    auto tracer = std::make_shared<Tracer>(stackingHandler,
                                           sampler,
                                           batch,
                                           frameMetricsCollector,
                                           conditionTimeoutExecutor,
                                           plainSpanFactory,
                                           viewLoadSpanFactory,
                                           networkSpanFactory,
                                           spanStartCallbacks,
                                           spanEndCallbacks,
                                           ^(){});
    
    SpanOptions spanOptions;
    auto span = tracer->startSpan(@"TestSpan", spanOptions, BSGTriStateYes, @[]);
    XCTAssertEqual(span.kind, SPAN_KIND_INTERNAL);
    XCTAssertEqualObjects(span.name, @"TestSpan");
    XCTAssertEqual(span.samplingProbability, expectedSamplingProbability);
}

@end
