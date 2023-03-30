//
//  Sampler.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 26/10/2022.
//

#pragma once

#import "IdGenerator.h"
#import "SpanData.h"

#import <Foundation/Foundation.h>
#import <vector>
#import <memory>

namespace bugsnag {

/**
 * Samples spans based on either:
 * - A default fallback probability
 * - A value that was set using setProbability(), which expires after 24 hours
 */
class Sampler {
public:
    Sampler(double fallbackProbability) noexcept;
    
    void setFallbackProbability(double value) noexcept;

    /**
     * Sets the probability value to use in all sampling for the next 24 hours.
     */
    void setProbability(double probability) noexcept;

    double getProbability() noexcept;

    /**
     * Samples the given span data, returning true if the span is to be kept.
     * Also updates the span's sampling probability value if it is to be kept.
     */
    bool sampled(SpanData &span) noexcept;

    /**
     * Samples the given set of span data, returning those that are to be kept.
     * Also updates the sampling probability value of each kept span.
     */
    std::unique_ptr<std::vector<std::shared_ptr<SpanData>>>
    sampled(std::unique_ptr<std::vector<std::shared_ptr<SpanData>>> spans) noexcept;

private:
    double probability_{0};
};
}
