//
//  Tracer.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import <BugsnagPerformance/BugsnagPerformanceViewType.h>
#import "Sampler.h"
#import "Batch.h"
#import "SpanOptions.h"
#import "PhasedStartup.h"
#import "SpanAttributesProvider.h"
#import "SpanStackingHandler.h"
#import "WeakSpansList.h"
#import "FrameRateMetrics/FrameMetricsCollector.h"
#import "ConditionTimeoutExecutor.h"
#import "Instrumentation/AppStartupInstrumentation/State/AppStartupInstrumentationStateSnapshot.h"
#import "BSGPrioritizedStore.h"
#import "SpanFactory/Plain/PlainSpanFactoryImpl.h"
#import "SpanFactory/AppStartup/AppStartupSpanFactoryImpl.h"
#import "SpanFactory/ViewLoad/ViewLoadSpanFactoryImpl.h"
#import "SpanFactory/Network/NetworkSpanFactoryImpl.h"
#import "SpanFactory/ViewLoad/ViewLoadSpanFactoryCallbacks.h"

#import <memory>

namespace bugsnag {
// https://opentelemetry.io/docs/reference/specification/trace/api/#tracer

/**
 * Tracer starts all spans, then samples them and routes them to the batch when they end.
 */
class Tracer: public PhasedStartup {
public:
    Tracer(std::shared_ptr<SpanStackingHandler> spanStackingHandler,
           std::shared_ptr<Sampler> sampler,
           std::shared_ptr<Batch> batch,
           FrameMetricsCollector *frameMetricsCollector,
           std::shared_ptr<ConditionTimeoutExecutor> conditionTimeoutExecutor,
           std::shared_ptr<PlainSpanFactoryImpl> plainSpanFactory,
           std::shared_ptr<ViewLoadSpanFactoryImpl> viewLoadSpanFactory,
           std::shared_ptr<NetworkSpanFactoryImpl> networkSpanFactory,
           BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> *onSpanStartCallbacks,
           BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> *onSpanEndCallbacks,
           void (^onSpanStarted)()) noexcept
    : spanStackingHandler_(spanStackingHandler)
    , sampler_(sampler)
    , prewarmSpans_([NSMutableArray new])
    , blockedSpans_([NSMutableArray new])
    , potentiallyOpenSpans_(std::make_shared<WeakSpansList>())
    , batch_(batch)
    , frameMetricsCollector_(frameMetricsCollector)
    , conditionTimeoutExecutor_(conditionTimeoutExecutor)
    , plainSpanFactory_(plainSpanFactory)
    , viewLoadSpanFactory_(viewLoadSpanFactory)
    , networkSpanFactory_(networkSpanFactory)
    , onSpanStartCallbacks_(onSpanStartCallbacks)
    , onSpanEndCallbacks_(onSpanEndCallbacks)
    , onSpanStarted_(onSpanStarted)
    {
        plainSpanFactory_->setup(createPlainSpanFactoryCallbacks());
        viewLoadSpanFactory_->setup(createViewLoadSpanFactoryCallbacks());
    }
    
    
    ~Tracer() {};

    void earlyConfigure(BSGEarlyConfiguration *) noexcept;
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *config) noexcept {
        plainSpanFactory_->setAttributeCountLimit(config.attributeCountLimit);
        enabledMetrics_ = [config.enabledMetrics clone];
    };
    void preStartSetup() noexcept;
    void start() noexcept {}

    void setOnViewLoadSpanStarted(std::function<void(NSString *)> onViewLoadSpanStarted) noexcept {
        onViewLoadSpanStarted_ = onViewLoadSpanStarted;
    }
    
    void setGetAppStartInstrumentationState(std::function<AppStartupInstrumentationStateSnapshot *()> getAppStartupInstrumentationState) noexcept {
        getAppStartupInstrumentationState_ = getAppStartupInstrumentationState;
    }

    BugsnagPerformanceSpan *startSpan(NSString *name, SpanOptions options, BSGTriState defaultFirstClass, NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept;

    BugsnagPerformanceSpan *startCustomSpan(NSString *name, SpanOptions options) noexcept;

    BugsnagPerformanceSpan *startViewLoadSpan(BugsnagPerformanceViewType viewType,
                                              NSString *className,
                                              SpanOptions options) noexcept;

    BugsnagPerformanceSpan *startNetworkSpan(NSString *httpMethod, SpanOptions options) noexcept;

    BugsnagPerformanceSpan *startViewLoadPhaseSpan(NSString *className,
                                                   NSString *phase,
                                                   BugsnagPerformanceSpanContext *parentContext,
                                                   NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept;

    void cancelQueuedSpan(BugsnagPerformanceSpan *span) noexcept;

    void onPrewarmPhaseEnded(void) noexcept;
    
    void abortAllOpenSpans() noexcept;

    // Sweep must be called periodically to avoid a buildup of dead pointers.
    void sweep() noexcept;

    void callOnSpanEndCallbacks(BugsnagPerformanceSpan *span);

private:
    Tracer() = delete;
    std::shared_ptr<Sampler> sampler_;
    std::shared_ptr<SpanStackingHandler> spanStackingHandler_;
    FrameMetricsCollector *frameMetricsCollector_;
    std::shared_ptr<ConditionTimeoutExecutor> conditionTimeoutExecutor_;
    std::shared_ptr<PlainSpanFactoryImpl> plainSpanFactory_;
    std::shared_ptr<ViewLoadSpanFactoryImpl> viewLoadSpanFactory_;
    std::shared_ptr<NetworkSpanFactoryImpl> networkSpanFactory_;

    std::atomic<bool> willDiscardPrewarmSpans_{false};
    BugsnagPerformanceEnabledMetrics *enabledMetrics_{[BugsnagPerformanceEnabledMetrics withAllEnabled]};
    std::mutex prewarmSpansMutex_;
    NSMutableArray<BugsnagPerformanceSpan *> *prewarmSpans_;
    NSMutableArray<BugsnagPerformanceSpan *> *blockedSpans_;
    BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> *onSpanStartCallbacks_;
    BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> *onSpanEndCallbacks_;

    // Sloppy list of "open" spans. Some spans may have already been closed,
    // but span abort/end are idempotent so it doesn't matter.
    std::shared_ptr<WeakSpansList> potentiallyOpenSpans_;

    std::shared_ptr<Batch> batch_;
    void (^onSpanStarted_)(){ ^(){} };
    std::function<void(NSString *)> onViewLoadSpanStarted_{ [](NSString *){} };
    std::function<AppStartupInstrumentationStateSnapshot *()> getAppStartupInstrumentationState_{ [](){ return nil; } };

    PlainSpanFactoryCallbacks *createPlainSpanFactoryCallbacks() noexcept;
    ViewLoadSpanFactoryCallbacks *createViewLoadSpanFactoryCallbacks() noexcept;
    void createFrozenFrameSpan(NSTimeInterval startTime, NSTimeInterval endTime, BugsnagPerformanceSpanContext *parentContext) noexcept;
    void markPrewarmSpan(BugsnagPerformanceSpan *span) noexcept;
    void onSpanEndSet(BugsnagPerformanceSpan *span);
    void onSpanClosed(BugsnagPerformanceSpan *span);
    BugsnagPerformanceSpanCondition *onSpanBlocked(BugsnagPerformanceSpan *blocked, NSTimeInterval timeout);
    void reprocessEarlySpans(void);
    void processFrameMetrics(BugsnagPerformanceSpan *span) noexcept;
    bool shouldInstrumentRendering(BugsnagPerformanceSpan *span) noexcept;
    void callOnSpanStartCallbacks(BugsnagPerformanceSpan *span);
};
}
