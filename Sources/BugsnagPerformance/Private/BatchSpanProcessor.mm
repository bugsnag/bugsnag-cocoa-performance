//
//  BatchSpanProcessor.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 05/10/2022.
//

#import "BatchSpanProcessor.h"

using namespace bugsnag;

void
BatchSpanProcessor::onEnd(std::unique_ptr<SpanData> span) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    spans_.push_back(std::move(span));
    if (!exporter_) {
        return;
    }
    // TODO: batch up spans until a flush trigger is reached
    exporter_->exportSpans(std::move(spans_));
    NSCParameterAssert(spans_.empty());
}

void
BatchSpanProcessor::setSpanExporter(std::shared_ptr<SpanExporter> exporter) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    exporter_ = exporter;
    if (!spans_.empty()) {
        exporter->exportSpans(std::move(spans_));
        NSCParameterAssert(spans_.empty());
    }
}
