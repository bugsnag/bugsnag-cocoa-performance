//
//  SpanAttributesTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 21.01.25.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "TestHelpers.h"
#import "../../Sources/BugsnagPerformance/Private/Core/Attributes/SpanAttributesProvider.h"

using namespace bugsnag;

@interface SpanAttributesTests : XCTestCase

@end

@implementation SpanAttributesTests

- (void)testInitialNetworkSpanAttributes {
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());
    auto attributes = provider.initialNetworkSpanAttributes();
    XCTAssertEqual(2U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"network");
    XCTAssertEqualObjects(attributes[@"http.url"], @"unknown");
}

- (void)testNetworkSpanUrlAttributes {
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());
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

- (void)testInternalErrorAttributes {
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());
    NSError *error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    auto attributes = provider.internalErrorAttributes(error);
    XCTAssertEqual(1U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.instrumentation_message"], @"Error Domain=test Code=1 \"(null)\"");
}

- (void)testAppStartPhaseSpanAttributes {
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());

    auto attributes = provider.appStartPhaseSpanAttributes(@"phase1");
    XCTAssertEqual(2U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"app_start_phase");
    XCTAssertEqualObjects(attributes[@"bugsnag.phase"], @"phase1");
}

- (void)testAppStartSpanAttributes {
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());

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
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());

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

- (void)testPreloadViewLoadSpanAttributes {
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());

    auto attributes = provider.preloadViewLoadSpanAttributes(@"myView", BugsnagPerformanceViewTypeUIKit);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView (preload)");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"UIKit");

    attributes = provider.preloadViewLoadSpanAttributes(@"myView", BugsnagPerformanceViewTypeSwiftUI);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView (preload)");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"SwiftUI");

    attributes = provider.preloadViewLoadSpanAttributes(@"myView", (BugsnagPerformanceViewType)100);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView (preload)");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"?");
}

- (void)testPresentingViewLoadSpanAttributes {
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());

    auto attributes = provider.presentingViewLoadSpanAttributes(@"myView", BugsnagPerformanceViewTypeUIKit);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView (presentation)");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"UIKit");

    attributes = provider.presentingViewLoadSpanAttributes(@"myView", BugsnagPerformanceViewTypeSwiftUI);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView (presentation)");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"SwiftUI");

    attributes = provider.presentingViewLoadSpanAttributes(@"myView", (BugsnagPerformanceViewType)100);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView (presentation)");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"?");
}

- (void)testViewLoadPhaseSpanAttributes {
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());

    auto attributes = provider.viewLoadPhaseSpanAttributes(@"myView", @"myPhase");
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load_phase");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView");
    XCTAssertEqualObjects(attributes[@"bugsnag.phase"], @"myPhase");
}

- (void)testCustomSpanAttributes {
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());

    auto attributes = provider.customSpanAttributes();
    XCTAssertEqual(1U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"custom");
}

- (void)testCPUSampleAttributesInsufficient {
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());

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

- (void)testCPUAttributesNilIfInvalidCPUMeanTotal {
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(1),
        SystemInfoSampleData(2),
        SystemInfoSampleData(3),
    };

    auto attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);

    XCTAssertNil(attributes[@"bugsnag.system.cpu_measures_timestamps"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_measures_total"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_mean_total"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_measures_main_thread"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_mean_main_thread"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_measures_overhead"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_mean_overhead"]);
}

- (void)testCPUSampleAttributes {
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());
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
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());
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
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(1),
        SystemInfoSampleData(2),
    };

    samples[0].mainThreadCPUPct = 20;
    samples[1].mainThreadCPUPct = 50;

    // CPU_MEAN_TOTAL not available, not sending other CPU data
    auto attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_measures_timestamps"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_measures_main_thread"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_mean_main_thread"]);
}

- (void)testCPUSampleAttributesOverheadOnly {
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(1),
        SystemInfoSampleData(2),
    };

    samples[0].monitorThreadCPUPct = 30;
    samples[1].monitorThreadCPUPct = 60;

    // CPU_MEAN_TOTAL not available, not sending other CPU data
    auto attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_measures_timestamps"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_measures_overhead"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_mean_overhead"]);
}

- (void)testCPUSampleAttributesComplex {
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());
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

- (void)testMemorySampleAttributesInsufficient {
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());

    // Not enough samples
    std::vector<SystemInfoSampleData> samples;
    auto attributes = provider.memorySampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);

    // Still not enough samples
    samples.push_back(SystemInfoSampleData(1));
    attributes = provider.memorySampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);

    // Both samples don't contain any valid data
    samples.push_back(SystemInfoSampleData(2));
    attributes = provider.memorySampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);

    // Only one sample contains valid data and we need at least 2
    samples[0].physicalMemoryBytesTotal = 10000;
    samples[1].physicalMemoryBytesInUse = 1000;
    attributes = provider.memorySampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);
}

- (void)testMemorySampleAttributesProcessOnly {
    SpanAttributesProvider provider = SpanAttributesProvider([[AppStateTracker alloc] init],
                                                             std::make_shared<Reachability>());
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(11),
        SystemInfoSampleData(12),
    };

    samples[0].physicalMemoryBytesTotal = 100;
    samples[0].physicalMemoryBytesInUse = 80;
    samples[1].physicalMemoryBytesTotal = 100;
    samples[1].physicalMemoryBytesInUse = 50;

    auto attributes = provider.memorySampleAttributes(samples);
    XCTAssertEqual(4U, attributes.count);
    NSArray *expectedTimestamps = @[
        @978307211000000000,
        @978307212000000000,
    ];
    NSArray *expectedMemory = @[
        @80.0,
        @50.0,
    ];
    XCTAssertEqualObjects(attributes[@"bugsnag.system.memory.timestamps"], expectedTimestamps);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.memory.spaces.device.size"], @100);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.memory.spaces.device.used"], expectedMemory);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.memory.spaces.device.mean"], @65.0);
}


@end
