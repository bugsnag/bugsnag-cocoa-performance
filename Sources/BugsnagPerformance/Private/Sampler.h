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

    void setProbability(double probability) noexcept {probability_ = probability;};

    double getProbability() noexcept {return probability_;};

    /**
     * Samples the given span data, returning true if the span is to be kept.
     */
    bool sampled(BugsnagPerformanceSpan *span) noexcept {
        if (span == nil) {
            return false;
        }

        auto p = getProbability();
        uint64_t idUpperBound;
        if (p <= 0.0) {
            idUpperBound = 0;
        } else if (p >= 1.0) {
            idUpperBound = UINT64_MAX;
        } else {
            idUpperBound = uint64_t(p * double(UINT64_MAX));
        }
        return span.traceId.hi <= idUpperBound;
    }

private:
    double probability_{1};
};
}
