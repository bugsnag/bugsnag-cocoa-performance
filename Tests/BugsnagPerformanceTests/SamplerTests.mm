//
//  SamplerTests.mm
//  BugsnagPerformance-iOSTests
//
//  Created by Nick Dowell on 26/10/2022.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "../../Sources/BugsnagPerformance/Private/Sampler.h"
#import "../../Sources/BugsnagPerformance/Private/BugsnagPerformanceConfiguration+Private.h"

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

- (void)testProbability {
    Sampler sampler;
    sampler.setProbability(1.0);
    XCTAssertEqual(sampler.getProbability(), 1.0);
    
    sampler.setProbability(0.5);
    XCTAssertEqual(sampler.getProbability(), 0.5);

    Sampler sampler2;
    sampler2.setProbability(0.8);
    XCTAssertEqual(sampler2.getProbability(), 0.8);
    XCTAssertEqual(sampler.getProbability(), 0.5);
}

- (void)testProbabilityAccuracy {
    // The RNG prior to ios 12 is too streaky
    if (@available(ios 12.0, *)) {
        std::vector<double> values { 0.0, 1.0 / 3.0, 0.5, 2.0 / 3.0, 1.0 };
        for (auto p : values) {
            Sampler sampler;
            sampler.setProbability(p);
            [self assertSampler:sampler samplesWithProbability:p];
        }
    }
}

- (void)assertSampler:(Sampler &)sampler samplesWithProbability:(double)probability {
    auto numSamplesTries = 1'000;
    auto count = 0;
    for (auto i = 0; i < numSamplesTries; i++) {
        BugsnagPerformanceSpan *span = [[BugsnagPerformanceSpan alloc] initWithName:@"a"
                                                                            traceId:IdGenerator::generateTraceId()
                                                                             spanId:IdGenerator::generateSpanId()
                                                                           parentId:0
                                                                          startTime:0
                                                                         firstClass:BSGFirstClassUnset
                                                                attributeCountLimit:128
                                                                instrumentRendering:BSGInstrumentRenderingNo
                                                                       onSpanEndSet:^(BugsnagPerformanceSpan * _Nonnull) {}
                                                                       onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {
        }];
        if (sampler.sampled(span)) {
            count++;
        }
    }
    auto proportionSampled = double(count) / double(numSamplesTries);
    // Allow for a large amount of slop (+/- 10%) in number of sampled traces, to avoid flakiness.
    XCTAssertTrue(proportionSampled < probability + 0.1 && proportionSampled > probability - 0.1);
}

@end
