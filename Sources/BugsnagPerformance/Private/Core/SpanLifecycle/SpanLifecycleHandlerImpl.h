//
//  SpanLifecycleHandlerImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 09/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once


#import "SpanLifecycleHandler.h"
#import "../SpanProcessingPipeline/Batch.h"
#import "../Configuration/BugsnagPerformanceConfiguration+Private.h"
#import "../../Metrics/FrameMetrics/FrameMetricsSnapshot.h"
#import "../SpanStack/SpanStackingHandler.h"
#import "../Sampler/Sampler.h"
#import "../SpanFactory/Plain/PlainSpanFactoryImpl.h"
#import "../SpanConditions/ConditionTimeoutExecutor.h"
#import "../BSGPrioritizedStore.h"
#import "../SpanStore/SpanStore.h"
#import "../SpanProcessingPipeline/SpanProcessingPipeline.h"

#import <mutex>

namespace bugsnag {

class SpanLifecycleHandlerImpl: public SpanLifecycleHandler {
public:
    SpanLifecycleHandlerImpl(std::shared_ptr<Sampler> sampler,
                             std::shared_ptr<SpanStore> store,
                             std::shared_ptr<ConditionTimeoutExecutor> conditionTimeoutExecutor,
                             std::shared_ptr<PlainSpanFactoryImpl> plainSpanFactory,
                             std::shared_ptr<SpanProcessingPipeline> pipeline,
                             BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> *onSpanStartCallbacks) noexcept
    : sampler_(sampler)
    , store_(store)
    , conditionTimeoutExecutor_(conditionTimeoutExecutor)
    , plainSpanFactory_(plainSpanFactory)
    , pipeline_(pipeline)
    , onSpanStartCallbacks_(onSpanStartCallbacks) {}
    
    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *config) noexcept {
        enabledMetrics_ = [config.enabledMetrics clone];
    }
    void preStartSetup() noexcept;
    void start() noexcept {
        isStarted_ = true;
    }
    
    void initialize(GetCurrentFrameMetricsSnapshot getCurrentSnapshot) noexcept {
        getCurrentSnapshot_ = getCurrentSnapshot;
    }
    
    void onAppEnteredBackground() noexcept;
    void onSpanStarted(BugsnagPerformanceSpan *span, const SpanOptions &options) noexcept;
    void onSpanEndSet(BugsnagPerformanceSpan *span) noexcept;
    void onSpanClosed(BugsnagPerformanceSpan *span) noexcept;
    BugsnagPerformanceSpanCondition *onSpanBlocked(BugsnagPerformanceSpan *blocked, NSTimeInterval timeout) noexcept;
    void onSpanCancelled(BugsnagPerformanceSpan *span) noexcept;
    
private:
    
    std::shared_ptr<Sampler> sampler_;
    std::shared_ptr<ConditionTimeoutExecutor> conditionTimeoutExecutor_;
    std::shared_ptr<PlainSpanFactoryImpl> plainSpanFactory_;
    std::shared_ptr<SpanStore> store_;
    bool isStarted_{false};
    
    std::shared_ptr<SpanProcessingPipeline> pipeline_;
    BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> *onSpanStartCallbacks_;
    BugsnagPerformanceEnabledMetrics *enabledMetrics_{[BugsnagPerformanceEnabledMetrics withAllEnabled]};
    GetCurrentFrameMetricsSnapshot getCurrentSnapshot_{nullptr};
    
    void callOnSpanStartCallbacks(BugsnagPerformanceSpan *span) noexcept;
    void abortAllOpenSpans() noexcept;
    bool shouldInstrumentRendering(BugsnagPerformanceSpan *span) noexcept;
    
    SpanLifecycleHandlerImpl() = delete;
};
}
