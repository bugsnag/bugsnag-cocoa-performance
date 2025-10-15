//
//  SpanProcessingPipelineImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 14/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "SpanProcessingPipelineImpl.h"

using namespace bugsnag;

void
SpanProcessingPipelineImpl::preStartSetup() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    executeFlow(preStartFlow_, preStartSpans_);
    [preStartSpans_ removeAllObjects];
    isStarted_ = true;
}

void
SpanProcessingPipelineImpl::addSpanForProcessing(BugsnagPerformanceSpan *span) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    executeFlow(preprocessFlow_, @[span]);
    if (isStarted_) {
        batch_->add(span);
    } else {
        [preStartSpans_ addObject:span];
    }
}

void
SpanProcessingPipelineImpl::removeSpan(BugsnagPerformanceSpan *span) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (isStarted_) {
        batch_->removeSpan(span.traceIdHi, span.traceIdLo, span.spanId);
    } else {
        [preStartSpans_ removeObject:span];
    }
}

void
SpanProcessingPipelineImpl::processPendingSpansIfNeeded() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    auto spans = batch_->drain(false);
    if (spans.count > 0) {
        executeFlow(mainFlow_, spans);
    }
}

void
SpanProcessingPipelineImpl::addPreprocessStep(std::shared_ptr<SpanProcessingPipelineStep> step) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    preprocessFlow_->push_back(step);
}

void
SpanProcessingPipelineImpl::addPreStartStep(std::shared_ptr<SpanProcessingPipelineStep> step) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    preStartFlow_->push_back(step);
}

void
SpanProcessingPipelineImpl::addMainFlowStep(std::shared_ptr<SpanProcessingPipelineStep> step) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    mainFlow_->push_back(step);
}

#pragma mark Private

void
SpanProcessingPipelineImpl::executeFlow(std::vector<std::shared_ptr<SpanProcessingPipelineStep>> *flow,
                                        NSArray<BugsnagPerformanceSpan *> *spans) noexcept {
    if (!flow || !spans) {
        return;
    }
    NSMutableArray *spansToProcess = [spans mutableCopy];
    
    for (const auto& step : *flow) {
        NSMutableArray *spansToRemove = [NSMutableArray array];
        for (BugsnagPerformanceSpan *span in spansToProcess) {
            bool shouldContinueWithCurrentSpan = step->run(span);
            if (!shouldContinueWithCurrentSpan) {
                [spansToRemove addObject:span];
            }
        }
        [spansToProcess removeObjectsInArray:spansToRemove];
    }
}
