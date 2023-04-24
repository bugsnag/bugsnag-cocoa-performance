//
//  Sampler.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 26/10/2022.
//

#import "Sampler.h"
#import "BugsnagPerformanceConfiguration+Private.h"

using namespace bugsnag;

bool Sampler::sampled(SpanData &span) noexcept {
    auto p = getProbability();
    uint64_t idUpperBound;
    if (p <= 0.0) {
        idUpperBound = 0;
    } else if (p >= 1.0) {
        idUpperBound = UINT64_MAX;
    } else {
        idUpperBound = uint64_t(p * double(UINT64_MAX));
    }
    bool isSampled = span.traceId.hi <= idUpperBound;
    if (isSampled) {
        span.updateSamplingProbability(p);
    }

    return isSampled;

}

std::unique_ptr<std::vector<std::shared_ptr<SpanData>>>
Sampler::sampled(std::unique_ptr<std::vector<std::shared_ptr<SpanData>>> spans) noexcept {
    auto sampledSpans = std::make_unique<std::vector<std::shared_ptr<SpanData>>>();
    for (size_t i = 0; i < spans->size(); i++) {
        if (sampled(*(*spans)[i])) {
            sampledSpans->push_back((*spans)[i]);
        }
    }
    return sampledSpans;
}
