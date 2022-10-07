//
//  Span.m
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "Span.h"

#import "SpanProcessor.h"

using namespace bugsnag;

Span::Span(std::unique_ptr<SpanData> data, std::shared_ptr<class SpanProcessor> spanProcessor) noexcept
: data_(std::move(data))
, processor_(spanProcessor)
{}

void
Span::end(CFAbsoluteTime time) noexcept {
    if (!data_) {
        return;
    }
    data_->endTime = time;
    processor_->onEnd(std::move(data_));
    processor_.reset();
}
