//
//  PipelineStepsBuilder.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "../Core/PhasedStartup.h"
#import "../Core/Attributes/SpanAttributesProvider.h"
#import "../Core/BSGPrioritizedStore.h"
#import "../Core/Configuration/BugsnagPerformanceConfiguration+Private.h"
#import "../Core/Sampler/Sampler.h"
#import "../Core/SpanProcessingPipeline/SpanProcessingPipelineStep.h"
#import "../Core/SpanFactory/Plain/PlainSpanFactory.h"
#import "../Metrics/SystemMetrics/SystemInfoSampler.h"

#import <vector>
#import <memory>

namespace bugsnag {
class PipelineStepsBuilder: public PhasedStartup {
public:
    PipelineStepsBuilder(std::shared_ptr<SystemInfoSampler> systemInfoSampler,
                         std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                         std::shared_ptr<PlainSpanFactory> plainSpanFactory,
                         std::shared_ptr<Sampler> sampler,
                         BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> *onSpanEndCallbacks) noexcept
    : systemInfoSampler_(systemInfoSampler)
    , spanAttributesProvider_(spanAttributesProvider)
    , plainSpanFactory_(plainSpanFactory)
    , sampler_(sampler)
    , onSpanEndCallbacks_(onSpanEndCallbacks) {};
    
    ~PipelineStepsBuilder() {};
    
    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept {}
    void start() noexcept {}
    
    std::vector<std::shared_ptr<SpanProcessingPipelineStep>> buildPreprocessSteps() noexcept;
    std::vector<std::shared_ptr<SpanProcessingPipelineStep>> buildMainFlowSteps() noexcept;
private:
    
    BugsnagPerformanceConfiguration *configuration_;
    BugsnagPerformanceEnabledMetrics *enabledMetrics_{[BugsnagPerformanceEnabledMetrics withAllEnabled]};
    
    std::shared_ptr<SystemInfoSampler> systemInfoSampler_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    std::shared_ptr<PlainSpanFactory> plainSpanFactory_;
    std::shared_ptr<Sampler> sampler_;
    BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> *onSpanEndCallbacks_;
    
    std::shared_ptr<SpanProcessingPipelineStep> buildAddSystemMetricsStep() noexcept;
    std::shared_ptr<SpanProcessingPipelineStep> buildAddFrameMetricsStep() noexcept;
    std::shared_ptr<SpanProcessingPipelineStep> buildProcessConditionsStep() noexcept;
    std::shared_ptr<SpanProcessingPipelineStep> buildFilterOutSpansStep() noexcept;
    std::shared_ptr<SpanProcessingPipelineStep> buildRunEndCallbacksStep() noexcept;
    
    bool shouldSampleCPU(BugsnagPerformanceSpan *span) noexcept;
    bool shouldSampleMemory(BugsnagPerformanceSpan *span) noexcept;
    bool shouldInstrumentRendering(BugsnagPerformanceSpan *span) noexcept;
    
    void processFrameMetrics(BugsnagPerformanceSpan *span) noexcept;
    void createFrozenFrameSpan(NSTimeInterval startTime,
                               NSTimeInterval endTime,
                               BugsnagPerformanceSpanContext *parentContext) noexcept;
    void callOnSpanEndCallbacks(BugsnagPerformanceSpan *span) noexcept;
    void processSpanConditions(BugsnagPerformanceSpan *span) noexcept;
};
}
