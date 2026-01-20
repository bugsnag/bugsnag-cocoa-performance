//
//  Tracer.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import <BugsnagPerformance/BugsnagPerformanceViewType.h>
#import "PhasedStartup.h"
#import "SpanStackingHandler.h"
#import "Instrumentation/AppStartupInstrumentation/State/AppStartupInstrumentationStateSnapshot.h"
#import "SpanFactory/Plain/PlainSpanFactoryImpl.h"
#import "SpanFactory/AppStartup/AppStartupSpanFactoryImpl.h"
#import "SpanFactory/ViewLoad/ViewLoadSpanFactoryImpl.h"
#import "SpanFactory/Network/NetworkSpanFactoryImpl.h"
#import "SpanFactory/ViewLoad/ViewLoadSpanFactoryCallbacks.h"
#import "SpanLifecycle/SpanLifecycleHandler.h"
#import "SpanStore/SpanStore.h"

#import <memory>

namespace bugsnag {
// https://opentelemetry.io/docs/reference/specification/trace/api/#tracer

/**
 * Tracer starts all spans, then samples them and routes them to the batch when they end.
 */
class Tracer: public PhasedStartup {
public:
    Tracer(std::shared_ptr<PlainSpanFactoryImpl> plainSpanFactory,
           std::shared_ptr<ViewLoadSpanFactoryImpl> viewLoadSpanFactory,
           std::shared_ptr<NetworkSpanFactoryImpl> networkSpanFactory,
           std::shared_ptr<SpanLifecycleHandler> spanLifecycleHandler,
           std::shared_ptr<SpanStore> spanStore) noexcept
    : plainSpanFactory_(plainSpanFactory)
    , viewLoadSpanFactory_(viewLoadSpanFactory)
    , networkSpanFactory_(networkSpanFactory)
    , spanLifecycleHandler_(spanLifecycleHandler)
    , spanStore_(spanStore)
    {
        plainSpanFactory_->setup(createPlainSpanFactoryCallbacks());
        viewLoadSpanFactory_->setup(createViewLoadSpanFactoryCallbacks());
    }
    
    
    ~Tracer() {};

    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *config) noexcept {
        plainSpanFactory_->setAttributeCountLimit(config.attributeCountLimit);
    };
    void preStartSetup() noexcept {}
    void start() noexcept {}

    void setOnViewLoadSpanStarted(std::function<void(NSString *)> onViewLoadSpanStarted) noexcept {
        onViewLoadSpanStarted_ = onViewLoadSpanStarted;
    }
    
    void setGetAppStartInstrumentationState(std::function<AppStartupInstrumentationStateSnapshot *()> getAppStartupInstrumentationState) noexcept {
        getAppStartupInstrumentationState_ = getAppStartupInstrumentationState;
    }

    BugsnagPerformanceSpan *startSpan(NSString *name, const SpanOptions &options, BSGTriState defaultFirstClass, NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept;

    BugsnagPerformanceSpan *startCustomSpan(NSString *name, const SpanOptions &options) noexcept;

    BugsnagPerformanceSpan *startViewLoadSpan(BugsnagPerformanceViewType viewType,
                                              NSString *className,
                                              const SpanOptions &options) noexcept;

    BugsnagPerformanceSpan *startNetworkSpan(NSString *httpMethod, const SpanOptions &options) noexcept;

    BugsnagPerformanceSpan *startViewLoadPhaseSpan(NSString *className,
                                                   NSString *phase,
                                                   BugsnagPerformanceSpanContext *parentContext,
                                                   NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept;
private:
    Tracer() = delete;
    std::shared_ptr<SpanStore> spanStore_;
    std::shared_ptr<PlainSpanFactoryImpl> plainSpanFactory_;
    std::shared_ptr<ViewLoadSpanFactoryImpl> viewLoadSpanFactory_;
    std::shared_ptr<NetworkSpanFactoryImpl> networkSpanFactory_;
    std::shared_ptr<SpanLifecycleHandler> spanLifecycleHandler_;

    std::function<void(NSString *)> onViewLoadSpanStarted_{ [](NSString *){} };
    std::function<AppStartupInstrumentationStateSnapshot *()> getAppStartupInstrumentationState_{ [](){ return nil; } };

    PlainSpanFactoryCallbacks *createPlainSpanFactoryCallbacks() noexcept;
    ViewLoadSpanFactoryCallbacks *createViewLoadSpanFactoryCallbacks() noexcept;
};
}
