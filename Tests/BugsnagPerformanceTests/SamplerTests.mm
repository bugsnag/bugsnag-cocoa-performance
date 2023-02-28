//
//  SamplerTests.mm
//  BugsnagPerformance-iOSTests
//
//  Created by Nick Dowell on 26/10/2022.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "../../Sources/BugsnagPerformance/Private/Sampler.h"

#import <vector>

using namespace bugsnag;

@interface SamplerTests : XCTestCase

@end

@implementation SamplerTests

- (void)setUp {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"BugsnagPerformanceSampler"];
}

- (void)tearDown {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"BugsnagPerformanceSampler"];
}

- (void)testProbabilityAccuracy {
    std::vector<double> values { 0.0, 1.0 / 3.0, 0.5, 2.0 / 3.0, 1.0 };
    for (auto p : values) {
        Sampler sampler(p);
        [self assertSampler:sampler samplesWithProbability:p];
    }
}

- (void)testProbabilityPersistence {
    auto defaultProbability = 1.0;
    Sampler sampler(defaultProbability);
    XCTAssertEqual(sampler.getProbability(), defaultProbability);
    
    sampler.setProbability(0.5);
    XCTAssertEqual(Sampler(1.0).getProbability(), 0.5);
}

- (void)assertSampler:(Sampler &)sampler samplesWithProbability:(double)probability {
    auto numSamplesTries = 1'000;
    auto count = 0;
    for (auto i = 0; i < numSamplesTries; i++) {
        SpanData spanData(@"a", IdGenerator::generateTraceId(), IdGenerator::generateSpanId(), 0, 0, false);
        if (sampler.sampled(spanData)) {
            count++;
        }
    }
    auto proportionSampled = double(count) / double(numSamplesTries);
    // Allow for a large amount of slop (+/- 10%) in number of sampled traces, to avoid flakiness.
    XCTAssertTrue(proportionSampled < probability + 0.1 && proportionSampled > probability - 0.1);
}

@end
