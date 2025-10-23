//
//  SpanProcessingPipelineImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 14/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "SpanProcessingPipelineImpl.h"

using namespace bugsnag;

#pragma mark PhaseStartup

void
SpanProcessingPipelineImpl::preStartSetup() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    auto spans = executeFlow(&preprocessFlow_, preStartSpans_);
    [preStartSpans_ removeAllObjects];
    for (BugsnagPerformanceSpan *span in spans) {
        batch_->add(span);
    }
    processPendingSpansIfNeeded();
    isStarted_ = true;
}

#pragma mark Public

void
SpanProcessingPipelineImpl::addSpanForProcessing(BugsnagPerformanceSpan *span) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    auto spans = executeFlow(&preprocessFlow_, @[span]);
    if (spans.count == 0) {
        return;
    }
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
    __block auto spans = batch_->drain(false);
    __block auto blockThis = this;
    if (spans.count > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((mainFlowDelay_ + 0.5) * NSEC_PER_SEC)),
                       dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0),^{
            blockThis->processPendingSpans(spans);
        });
    }
}

NSArray<BugsnagPerformanceSpan *> *
SpanProcessingPipelineImpl::drainSendableSpans() noexcept {
    NSArray<BugsnagPerformanceSpan *> *result = [sendableSpans_ copy];
    [sendableSpans_ removeAllObjects];
    return result;
}

#pragma mark Steps Management

void
SpanProcessingPipelineImpl::addPreprocessStep(std::shared_ptr<SpanProcessingPipelineStep> step) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    preprocessFlow_.push_back(step);
}

void
SpanProcessingPipelineImpl::addMainFlowStep(std::shared_ptr<SpanProcessingPipelineStep> step) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    mainFlow_.push_back(step);
}

#pragma mark Private

NSArray<BugsnagPerformanceSpan *> *
SpanProcessingPipelineImpl::executeFlow(std::vector<std::shared_ptr<SpanProcessingPipelineStep>> *flow,
                                        NSArray<BugsnagPerformanceSpan *> *spans) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (!flow || !spans) {
        return @[];
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
    return spansToProcess;
}

void
SpanProcessingPipelineImpl::processPendingSpans(NSArray<BugsnagPerformanceSpan *> *spans) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    auto spansToSend = executeFlow(&mainFlow_, spans);
    if (spansToSend.count > 0) {
        [sendableSpans_ addObjectsFromArray:spansToSend];
        if (onSendableSpans_) {
            onSendableSpans_();
        }
    }
}
