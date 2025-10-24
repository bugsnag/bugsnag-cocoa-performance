//
//  SpanProcessingPipelineImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 14/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "SpanProcessingPipeline.h"
#import "Batch.h"
#import "../PhasedStartup.h"
#import "SpanProcessingPipelineStep.h"

#import <vector>
#import <memory>
#import <mutex>

namespace bugsnag {

class SpanProcessingPipelineImpl: public SpanProcessingPipeline, public PhasedStartup {
public:
    SpanProcessingPipelineImpl(std::shared_ptr<Batch> batch) noexcept
    : batch_(batch)
    , preStartSpans_([NSMutableArray new])
    , sendableSpans_([NSMutableArray new]) {}
    
    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *) noexcept {}
    void preStartSetup() noexcept;
    void start() noexcept {}
    
    void setMainFlowDelay(double delay) noexcept { mainFlowDelay_ = delay; }
    
    void addSpanForProcessing(BugsnagPerformanceSpan *span) noexcept;
    void removeSpan(BugsnagPerformanceSpan *span) noexcept;
    void processPendingSpansIfNeeded() noexcept;
    NSArray<BugsnagPerformanceSpan *> *drainSendableSpans() noexcept;
    
    void setSendableSpansCallback(void (^sendableSpansCallback)()) {
        onSendableSpans_ = sendableSpansCallback;
    }
    
    void addPreprocessStep(std::shared_ptr<SpanProcessingPipelineStep> step) noexcept;
    void addMainFlowStep(std::shared_ptr<SpanProcessingPipelineStep> step) noexcept;
    
private:
    bool isStarted_{false};
    double mainFlowDelay_{0.0};
    void (^onSendableSpans_)(){nullptr};
    std::shared_ptr<Batch> batch_;
    NSMutableArray<BugsnagPerformanceSpan *> *preStartSpans_;
    NSMutableArray<BugsnagPerformanceSpan *> *sendableSpans_;
    std::vector<std::shared_ptr<SpanProcessingPipelineStep>> preprocessFlow_{};
    std::vector<std::shared_ptr<SpanProcessingPipelineStep>> mainFlow_{};
    
    std::recursive_mutex mutex_;
    
    NSArray<BugsnagPerformanceSpan *> *executeFlow(std::vector<std::shared_ptr<SpanProcessingPipelineStep>> *flow,
                                                   NSArray<BugsnagPerformanceSpan *> *spans) noexcept;
    void processPendingSpans(NSArray<BugsnagPerformanceSpan *> *spans) noexcept;
};
}
