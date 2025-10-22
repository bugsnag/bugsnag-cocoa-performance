//
//  InstrumentationModule.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "Instrumentation.h"
#import "AppStartupInstrumentation/State/AppStartupInstrumentationStateSnapshot.h"
#import "../Core/Module.h"
#import "../Core/AppLifecycleListener.h"
#import "../Core/Attributes/SpanAttributesProvider.h"
#import "../Core/Sampler/Sampler.h"
#import "../Core/SpanFactory/AppStartup/AppStartupSpanFactory.h"
#import "../Core/SpanFactory/ViewLoad/ViewLoadSpanFactory.h"
#import "../Core/SpanFactory/Network/NetworkSpanFactory.h"
#import "../Core/SpanStack/SpanStackingHandler.h"

namespace bugsnag {
class InstrumentationModule: public Module, AppLifecycleListener {
public:
    InstrumentationModule(std::shared_ptr<AppStartupSpanFactory> appStartupSpanFactory,
                          std::shared_ptr<ViewLoadSpanFactory> viewLoadSpanFactory,
                          std::shared_ptr<NetworkSpanFactory> networkSpanFactory,
                          std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                          std::shared_ptr<SpanStackingHandler> spanStackingHandler,
                          std::shared_ptr<Sampler> sampler)
    : appStartupSpanFactory_(appStartupSpanFactory)
    , viewLoadSpanFactory_(viewLoadSpanFactory)
    , networkSpanFactory_(networkSpanFactory)
    , spanAttributesProvider_(spanAttributesProvider)
    , spanStackingHandler_(spanStackingHandler)
    , sampler_(sampler) {};
    
    ~InstrumentationModule() {};
    
    void earlyConfigure(BSGEarlyConfiguration *) noexcept;
    void earlySetup() noexcept;
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept;
    void start() noexcept;
    
    void setUp() noexcept;
    
    void onAppFinishedLaunching() noexcept;
    void onAppEnteredBackground() noexcept;
    void onAppEnteredForeground() noexcept;
    
    void loadingIndicatorWasAdded(BugsnagPerformanceLoadingIndicatorView *loadingViewIndicator) noexcept {
        instrumentation_->loadingIndicatorWasAdded(loadingViewIndicator);
    }
    
    // Tasks
    
    GetAppStartupStateSnapshot getAppStartupStateSnapshotTask() noexcept;
    HandleStringTask getHandleViewLoadSpanStartedTask() noexcept;
    
    // Component access
    
    std::shared_ptr<NetworkHeaderInjector> getNetworkHeaderInjector() noexcept { return networkHeaderInjector_; }
    std::shared_ptr<Instrumentation> getInstrumentation() noexcept { return instrumentation_; }
    
private:
    
    // Dependencies
    std::shared_ptr<AppStartupSpanFactory> appStartupSpanFactory_;
    std::shared_ptr<ViewLoadSpanFactory> viewLoadSpanFactory_;
    std::shared_ptr<NetworkSpanFactory> networkSpanFactory_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    std::shared_ptr<SpanStackingHandler> spanStackingHandler_;
    std::shared_ptr<Sampler> sampler_;
    
    // Components
    std::shared_ptr<NetworkHeaderInjector> networkHeaderInjector_;
    std::shared_ptr<Instrumentation> instrumentation_;
    
    InstrumentationModule() = delete;
};
}
