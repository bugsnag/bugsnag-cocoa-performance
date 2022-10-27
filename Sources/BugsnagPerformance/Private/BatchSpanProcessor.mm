//
//  BatchSpanProcessor.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 05/10/2022.
//

#import "BatchSpanProcessor.h"

#import "Sampler.h"

using namespace bugsnag;

BatchSpanProcessor::BatchSpanProcessor(std::shared_ptr<class Sampler> sampler) noexcept
: sampler_(sampler)
{}

void
BatchSpanProcessor::onEnd(std::unique_ptr<SpanData> span) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (!shouldSample(span)) {
        // This span should not be sampled; discard.
        return;
    }
    spans_.push_back(std::move(span));
    // TODO: batch up spans until a flush trigger is reached
    exportSpans();
}

void
BatchSpanProcessor::setSpanExporter(std::shared_ptr<SpanExporter> exporter) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    exporter_ = exporter;
    exportSpans();
}

bool
BatchSpanProcessor::shouldSample(std::unique_ptr<SpanData> &span) noexcept {
    auto decision = sampler_->shouldSample(span->traceId); 
    if (!decision.isSampled) {
        return false;
    }
    span->updateSamplingProbability(decision.sampledProbability);
    return true;
}

void
BatchSpanProcessor::exportSpans() noexcept {
    // Resample in case probability changed
    std::remove_if(std::begin(spans_), std::end(spans_), [&](auto &span){
        return !shouldSample(span);
    });
    if (!exporter_ || spans_.empty()) {
        return;
    }
    exporter_->exportSpans(std::move(spans_));
    NSCParameterAssert(spans_.empty());
}
