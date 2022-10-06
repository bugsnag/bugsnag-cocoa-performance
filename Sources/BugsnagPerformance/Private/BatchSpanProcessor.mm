//
//  BatchSpanProcessor.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 05/10/2022.
//

#import "BatchSpanProcessor.h"

using namespace bugsnag;

void
BatchSpanProcessor::onEnd(SpanPtr span) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (!exporter_) {
        spans_.push_back(span);
        return;
    }
    // TODO: batch up spans until a flush trigger is reached
    exporter_->exportSpans(std::vector<SpanPtr>({span}));
}

void
BatchSpanProcessor::setSpanExporter(std::shared_ptr<SpanExporter> exporter) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    exporter_ = exporter;
    if (!spans_.empty()) {
        exporter->exportSpans(spans_);
        spans_.clear();
    }
}
