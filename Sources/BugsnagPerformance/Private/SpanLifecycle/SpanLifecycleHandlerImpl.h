//
//  SpanLifecycleHandlerImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 09/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//


#import "SpanLifecycleHandler.h"
#import "../Batch.h"
#import "../BugsnagPerformanceConfiguration+Private.h"
#import "../FrameRateMetrics/FrameMetricsCollector.h"
#import "../SpanStackingHandler.h"
#import "../Sampler.h"
#import "../SpanFactory/Plain/PlainSpanFactoryImpl.h"
#import "../ConditionTimeoutExecutor.h"
#import "../BSGPrioritizedStore.h"
#import "../WeakSpansList.h"

#import <mutex>

namespace bugsnag {

class SpanLifecycleHandlerImpl: public SpanLifecycleHandler {
public:
    SpanLifecycleHandlerImpl(std::shared_ptr<Sampler> sampler,
                             std::shared_ptr<SpanStackingHandler> spanStackingHandler,
                             std::shared_ptr<ConditionTimeoutExecutor> conditionTimeoutExecutor,
                             std::shared_ptr<PlainSpanFactoryImpl> plainSpanFactory,
                             std::shared_ptr<Batch> batch,
                             FrameMetricsCollector *frameMetricsCollector,
                             BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> *onSpanStartCallbacks,
                             BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> *onSpanEndCallbacks,
                             void (^onSpanStarted)()) noexcept
    : sampler_(sampler)
    , spanStackingHandler_(spanStackingHandler)
    , conditionTimeoutExecutor_(conditionTimeoutExecutor)
    , plainSpanFactory_(plainSpanFactory)
    , batch_(batch)
    , frameMetricsCollector_(frameMetricsCollector)
    , onSpanStartCallbacks_(onSpanStartCallbacks)
    , onSpanEndCallbacks_(onSpanEndCallbacks)
    , onSpanStarted_(onSpanStarted)
    , blockedSpans_([NSMutableArray new])
    , potentiallyOpenSpans_(std::make_shared<WeakSpansList>()) {}
    
    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *config) noexcept {
        enabledMetrics_ = [config.enabledMetrics clone];
    }
    void preStartSetup() noexcept;
    void start() noexcept {
        isStarted_ = true;
    }
    
    void onAppEnteredBackground() noexcept;
    void onSpanStarted(BugsnagPerformanceSpan *span, const SpanOptions &options) noexcept;
    void onSpanEndSet(BugsnagPerformanceSpan *span) noexcept;
    void onSpanClosed(BugsnagPerformanceSpan *span) noexcept;
    BugsnagPerformanceSpanCondition *onSpanBlocked(BugsnagPerformanceSpan *blocked, NSTimeInterval timeout) noexcept;
    void onSpanCancelled(BugsnagPerformanceSpan *span) noexcept;
    
    void sweep() noexcept;
    
private:
    
    std::shared_ptr<Sampler> sampler_;
    std::shared_ptr<SpanStackingHandler> spanStackingHandler_;
    std::shared_ptr<ConditionTimeoutExecutor> conditionTimeoutExecutor_;
    std::shared_ptr<PlainSpanFactoryImpl> plainSpanFactory_;
    FrameMetricsCollector *frameMetricsCollector_;
    bool isStarted_{false};
    void (^onSpanStarted_)(){ ^(){} };
    
    std::shared_ptr<Batch> batch_;
    std::shared_ptr<WeakSpansList> potentiallyOpenSpans_;
    NSMutableArray<BugsnagPerformanceSpan *> *blockedSpans_;
    BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> *onSpanStartCallbacks_;
    BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> *onSpanEndCallbacks_;
    BugsnagPerformanceEnabledMetrics *enabledMetrics_{[BugsnagPerformanceEnabledMetrics withAllEnabled]};
    
    void processClosedSpan(BugsnagPerformanceSpan *span) noexcept;
    void cancelQueuedSpan(BugsnagPerformanceSpan *span) noexcept;
    bool shouldInstrumentRendering(BugsnagPerformanceSpan *span) noexcept;
    void processFrameMetrics(BugsnagPerformanceSpan *span) noexcept;
    void callOnSpanStartCallbacks(BugsnagPerformanceSpan *span) noexcept;
    void callOnSpanEndCallbacks(BugsnagPerformanceSpan *span) noexcept;
    void createFrozenFrameSpan(NSTimeInterval startTime,
                               NSTimeInterval endTime,
                               BugsnagPerformanceSpanContext *parentContext) noexcept;
    void abortAllOpenSpans() noexcept;
    void reprocessEarlySpans() noexcept;
    
    SpanLifecycleHandlerImpl() = delete;
};
}
