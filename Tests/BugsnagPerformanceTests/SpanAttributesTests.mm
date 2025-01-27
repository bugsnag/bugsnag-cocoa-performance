//
//  SpanAttributesTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 21.01.25.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "TestHelpers.h"
#import "../../Sources/BugsnagPerformance/Private/SpanAttributesProvider.h"

using namespace bugsnag;

@interface SpanAttributesTests : XCTestCase

@end

@implementation SpanAttributesTests

- (void)testNetworkSpanUrlAttributes {
    SpanAttributesProvider provider;
    NSURL *url = [NSURL URLWithString:@"https://bugsnag.com"];
    NSError *error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];

    auto attributes = provider.networkSpanUrlAttributes(url, error);
    XCTAssertEqual(2U, attributes.count);
    XCTAssertEqualObjects(attributes[@"http.url"], url.absoluteString);
    XCTAssertEqualObjects(attributes[@"bugsnag.instrumentation_message"], @"Error Domain=test Code=1 \"(null)\"");

    attributes = provider.networkSpanUrlAttributes(url, nil);
    XCTAssertEqual(1U, attributes.count);
    XCTAssertEqualObjects(attributes[@"http.url"], url.absoluteString);
    XCTAssertNil(attributes[@"bugsnag.instrumentation_message"]);

    attributes = provider.networkSpanUrlAttributes(nil, error);
    XCTAssertEqual(1U, attributes.count);
    XCTAssertNil(attributes[@"http.url"]);
    XCTAssertEqualObjects(attributes[@"bugsnag.instrumentation_message"], @"Error Domain=test Code=1 \"(null)\"");

    attributes = provider.networkSpanUrlAttributes(nil, nil);
    XCTAssertEqual(0U, attributes.count);
}

- (void)testAppStartPhaseSpanAttributes {
    SpanAttributesProvider provider;

    auto attributes = provider.appStartPhaseSpanAttributes(@"phase1");
    XCTAssertEqual(2U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"app_start_phase");
    XCTAssertEqualObjects(attributes[@"bugsnag.phase"], @"phase1");
}

- (void)testAppStartSpanAttributes {
    SpanAttributesProvider provider;

    auto attributes = provider.appStartSpanAttributes(@"firstView", true);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"app_start");
    XCTAssertEqualObjects(attributes[@"bugsnag.app_start.type"], @"cold");
    XCTAssertEqualObjects(attributes[@"bugsnag.app_start.first_view_name"], @"firstView");

    attributes = provider.appStartSpanAttributes(@"firstView", false);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"app_start");
    XCTAssertEqualObjects(attributes[@"bugsnag.app_start.type"], @"warm");
    XCTAssertEqualObjects(attributes[@"bugsnag.app_start.first_view_name"], @"firstView");

    attributes = provider.appStartSpanAttributes(nil, false);
    XCTAssertEqual(2U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"app_start");
    XCTAssertEqualObjects(attributes[@"bugsnag.app_start.type"], @"warm");
    XCTAssertNil(attributes[@"bugsnag.app_start.first_view_name"]);
}

- (void)testViewLoadSpanAttributes {
    SpanAttributesProvider provider;

    auto attributes = provider.viewLoadSpanAttributes(@"myView", BugsnagPerformanceViewTypeUIKit);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"UIKit");

    attributes = provider.viewLoadSpanAttributes(@"myView", BugsnagPerformanceViewTypeSwiftUI);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"SwiftUI");

    attributes = provider.viewLoadSpanAttributes(@"myView", (BugsnagPerformanceViewType)100);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"?");
}

- (void)testPreloadedViewLoadSpanAttributes {
    SpanAttributesProvider provider;

    auto attributes = provider.preloadedViewLoadSpanAttributes(@"myView", BugsnagPerformanceViewTypeUIKit);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView (pre-loaded)");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"UIKit");

    attributes = provider.preloadedViewLoadSpanAttributes(@"myView", BugsnagPerformanceViewTypeSwiftUI);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView (pre-loaded)");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"SwiftUI");

    attributes = provider.preloadedViewLoadSpanAttributes(@"myView", (BugsnagPerformanceViewType)100);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView (pre-loaded)");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"?");
}

- (void)testViewLoadPhaseSpanAttributes {
    SpanAttributesProvider provider;

    auto attributes = provider.viewLoadPhaseSpanAttributes(@"myView", @"myPhase");
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load_phase");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView");
    XCTAssertEqualObjects(attributes[@"bugsnag.phase"], @"myPhase");
}

- (void)testCustomSpanAttributes {
    SpanAttributesProvider provider;

    auto attributes = provider.customSpanAttributes();
    XCTAssertEqual(1U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"custom");
}

- (void)testCPUSampleAttributesInsufficient {
    SpanAttributesProvider provider;

    // Not enough samples
    std::vector<SystemInfoSampleData> samples;
    auto attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);

    // Still not enough samples
    samples.push_back(SystemInfoSampleData(1));
    attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);

    // Both samples don't contain any valid data
    samples.push_back(SystemInfoSampleData(2));
    attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);

    // Only one sample contains valid data and we need at least 2
    samples[0].mainThreadCPUPct = 10;
    attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);
}

- (void)testCPUSampleAttributes {
    SpanAttributesProvider provider;
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(1),
        SystemInfoSampleData(2),
    };

    samples[0].processCPUPct = 10;
    samples[0].mainThreadCPUPct = 20;
    samples[0].monitorThreadCPUPct = 30;

    samples[1].processCPUPct = 40;
    samples[1].mainThreadCPUPct = 50;
    samples[1].monitorThreadCPUPct = 60;

    auto attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(7U, attributes.count);
    NSArray *expectedTimestamps = @[
        @978307201000000000,
        @978307202000000000,
    ];
    NSArray *expectedProcess = @[
        @10.0,
        @40.0,
    ];
    NSArray *expectedMainThread = @[
        @20.0,
        @50.0,
    ];
    NSArray *expectedMonitorThread = @[
        @30.0,
        @60.0,
    ];
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_timestamps"], expectedTimestamps);

    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_total"], expectedProcess);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_total"], @25.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_main_thread"], expectedMainThread);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_main_thread"], @35.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_overhead"], expectedMonitorThread);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_overhead"], @45.0);
}

- (void)testCPUSampleAttributesProcessOnly {
    SpanAttributesProvider provider;
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(11),
        SystemInfoSampleData(12),
    };

    samples[0].processCPUPct = 10;
    samples[1].processCPUPct = 40;

    auto attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(3U, attributes.count);
    NSArray *expectedTimestamps = @[
        @978307211000000000,
        @978307212000000000,
    ];
    NSArray *expectedProcess = @[
        @10.0,
        @40.0,
    ];
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_timestamps"], expectedTimestamps);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_total"], expectedProcess);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_total"], @25.0);
}

- (void)testCPUSampleAttributesMainThreadOnly {
    SpanAttributesProvider provider;
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(1),
        SystemInfoSampleData(2),
    };

    samples[0].mainThreadCPUPct = 20;
    samples[1].mainThreadCPUPct = 50;

    auto attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(3U, attributes.count);
    NSArray *expectedTimestamps = @[
        @978307201000000000,
        @978307202000000000,
    ];
    NSArray *expectedMainThread = @[
        @20.0,
        @50.0,
    ];
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_timestamps"], expectedTimestamps);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_main_thread"], expectedMainThread);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_main_thread"], @35.0);
}

- (void)testCPUSampleAttributesOverheadOnly {
    SpanAttributesProvider provider;
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(1),
        SystemInfoSampleData(2),
    };

    samples[0].monitorThreadCPUPct = 30;
    samples[1].monitorThreadCPUPct = 60;

    auto attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(3U, attributes.count);
    NSArray *expectedTimestamps = @[
        @978307201000000000,
        @978307202000000000,
    ];
    NSArray *expectedMonitorThread = @[
        @30.0,
        @60.0,
    ];
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_timestamps"], expectedTimestamps);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_overhead"], expectedMonitorThread);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_overhead"], @45.0);
}

- (void)testCPUSampleAttributesComplex {
    SpanAttributesProvider provider;
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(1),
        SystemInfoSampleData(2),
        SystemInfoSampleData(3),
        SystemInfoSampleData(8),
        SystemInfoSampleData(9),
    };

    samples[0].processCPUPct = 10;
    samples[0].mainThreadCPUPct = -1;
    samples[0].monitorThreadCPUPct = 30;

    samples[1].processCPUPct = -1;
    samples[1].mainThreadCPUPct = -1;
    samples[1].monitorThreadCPUPct = 60;

    samples[2].processCPUPct = 40;
    samples[2].mainThreadCPUPct = 70;
    samples[2].monitorThreadCPUPct = 60;

    samples[3].processCPUPct = -1;
    samples[3].mainThreadCPUPct = -1;
    samples[3].monitorThreadCPUPct = -1;

    samples[4].processCPUPct = 70;
    samples[4].mainThreadCPUPct = 80;
    samples[4].monitorThreadCPUPct = -1;

    auto attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(7U, attributes.count);
    NSArray *expectedTimestamps = @[
        @978307201000000000,
        @978307202000000000,
        @978307203000000000,
        @978307209000000000,
    ];
    NSArray *expectedProcess = @[
        @10.0,
        @-1.0,
        @40.0,
        @70.0,
    ];
    NSArray *expectedMainThread = @[
        @-1.0,
        @-1.0,
        @70.0,
        @80.0,
    ];
    NSArray *expectedMonitorThread = @[
        @30.0,
        @60.0,
        @60.0,
        @-1.0,
    ];
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_timestamps"], expectedTimestamps);

    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_total"], expectedProcess);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_total"], @40.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_main_thread"], expectedMainThread);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_main_thread"], @75.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_overhead"], expectedMonitorThread);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_overhead"], @50.0);
}

@end
