//
//  Sampler.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 26/10/2022.
//

#pragma once

#import "IdGenerator.h"
#import "BugsnagPerformanceSpan+Private.h"

#import <Foundation/Foundation.h>
#import <vector>
#import <memory>

namespace bugsnag {

/**
 * Samples spans based on the currently configured probability
 */
class Sampler {
public:
    // Sampler constructs with a probability of 1 so that it keeps everything until explicitly configured.
    Sampler() noexcept
    : probability_(1)
    {}
    
    static bool calculateIsSampled(TraceId traceId, double samplingProbability) {
        if (samplingProbability <= 0.0) {
            return false;
        }
        
        uint64_t idUpperBound;
        if (samplingProbability >= 1.0) {
            idUpperBound = UINT64_MAX;
        } else {
            idUpperBound = uint64_t(samplingProbability * double(UINT64_MAX));
        }
        return traceId.hi <= idUpperBound;
    }

    void setProbability(double probability) noexcept {probability_ = probability;};

    double getProbability() noexcept {return probability_;};

    /**
     * Samples the given span data, returning true if the span is to be kept.
     */
    bool sampled(BugsnagPerformanceSpan *span) noexcept {
        if (span == nil) {
            BSGLogDebug(@"[TEST] sampling: span is nil");
            return false;
        }

        auto p = getProbability();
        auto isSampled = calculateIsSampled(span.traceId, p);
        if (isSampled) {
            [span forceMutate:^{
                [span updateSamplingProbability:p];
            }];
        } else {
            BSGLogDebug(@"[TEST] sampling: span is not sampled. Probability: %f", p);
        }
        
        return isSampled;
    }

private:
    double probability_{1};
};
}
