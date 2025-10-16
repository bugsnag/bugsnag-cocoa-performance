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
    SpanProcessingPipelineImpl() noexcept
    : batch_(std::make_shared<Batch>())
    , preStartSpans_([NSMutableArray new]) {}
    
    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *) noexcept {}
    void preStartSetup() noexcept;
    void start() noexcept {}
    
    void addSpanForProcessing(BugsnagPerformanceSpan *span) noexcept;
    void removeSpan(BugsnagPerformanceSpan *span) noexcept;
    void processPendingSpansIfNeeded() noexcept;
    
    void addPreprocessStep(std::shared_ptr<SpanProcessingPipelineStep> step) noexcept;
    void addPreStartStep(std::shared_ptr<SpanProcessingPipelineStep> step) noexcept;
    void addMainFlowStep(std::shared_ptr<SpanProcessingPipelineStep> step) noexcept;
    
private:
    bool isStarted_{false};
    std::shared_ptr<Batch> batch_;
    NSMutableArray<BugsnagPerformanceSpan *> *preStartSpans_;
    std::vector<std::shared_ptr<SpanProcessingPipelineStep>> *preprocessFlow_{};
    std::vector<std::shared_ptr<SpanProcessingPipelineStep>> *preStartFlow_{};
    std::vector<std::shared_ptr<SpanProcessingPipelineStep>> *mainFlow_{};
    
    std::mutex mutex_;
    
    void executeFlow(std::vector<std::shared_ptr<SpanProcessingPipelineStep>> *flow,
                     NSArray<BugsnagPerformanceSpan *> *spans) noexcept;
};
}
