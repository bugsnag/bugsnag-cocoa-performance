//
//  Sampler.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 26/10/2022.
//

#import "Sampler.h"
#import "BugsnagPerformanceConfiguration+Private.h"
#import "BugsnagPerformanceSpan+Private.h"

using namespace bugsnag;

bool Sampler::sampled(BugsnagPerformanceSpan *span) noexcept {
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
    bool isSampled = span.traceId.hi <= idUpperBound;
    if (isSampled) {
        [span updateSamplingProbability:p];
    }

    return isSampled;

}
