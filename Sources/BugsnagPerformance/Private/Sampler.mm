//
//  Sampler.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 26/10/2022.
//

#import "Sampler.h"

using namespace bugsnag;

static const CFTimeInterval kProbabilityDuration = 24 * 3600;

static NSString *kUserDefaultsKey = @"BugsnagPerformanceSampler";
static NSString *kProbabilityKey = @"p";
static NSString *kExpiryKey = @"e";

Sampler::Sampler(double fallbackProbability) noexcept
: fallbackProbability_(fallbackProbability)
, probability_(0.0)
, probabilityExpiry_(0.0)
{
    if (NSDictionary *dict = [[NSUserDefaults standardUserDefaults]
                              dictionaryForKey:kUserDefaultsKey]) {
        id p = dict[kProbabilityKey], e = dict[kExpiryKey];
        if ([p isKindOfClass:[NSNumber class]] &&
            [e isKindOfClass:[NSNumber class]]) {
            probability_ = [p doubleValue];
            probabilityExpiry_ = [e doubleValue];
        }
    }
}

double
Sampler::getProbability() noexcept {
    if (CFAbsoluteTimeGetCurrent() < probabilityExpiry_) {
        return probability_;
    }
    return fallbackProbability_;
}

void
Sampler::setProbability(double probability) noexcept {
    auto expiry = CFAbsoluteTimeGetCurrent() + kProbabilityDuration;
    probability_ = probability;
    probabilityExpiry_ = expiry;
    
    [[NSUserDefaults standardUserDefaults]
     setObject:@{
        kProbabilityKey: @(probability),
        kExpiryKey: @(expiry)}
     forKey:kUserDefaultsKey];
}

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
    bool isSampled = span.traceId.hi < idUpperBound;
    if (isSampled) {
        span.updateSamplingProbability(p);
    }

    return isSampled;

}

std::unique_ptr<std::vector<std::unique_ptr<SpanData>>>
Sampler::sampled(std::unique_ptr<std::vector<std::unique_ptr<SpanData>>> spans) noexcept {
    auto sampledSpans = std::make_unique<std::vector<std::unique_ptr<SpanData>>>();
    for (size_t i = 0; i < spans->size(); i++) {
        if (sampled(*(*spans)[i])) {
            sampledSpans->push_back(std::move((*spans)[i]));
        }
    }
    return sampledSpans;
}
