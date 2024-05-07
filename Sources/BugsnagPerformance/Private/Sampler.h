//
//  Sampler.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 26/10/2022.
//

#pragma once

#import "IdGenerator.h"
#import "SpanData.h"
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
     * Also updates the span's sampling probability value if it is to be kept.
     */
    bool sampled(SpanData &span) noexcept;

    bool sampled(BugsnagPerformanceSpan *span) noexcept {
        return sampled(*span.span->data());
    }

    /**
     * Samples the given set of span data, returning those that are to be kept.
     * Also updates the sampling probability value of each kept span.
     */
    std::unique_ptr<std::vector<std::shared_ptr<SpanData>>>
    sampled(std::unique_ptr<std::vector<std::shared_ptr<SpanData>>> spans) noexcept;

private:
    double probability_{1};
};
}
