//
//  Instrumentation.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 24.04.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceLoadingIndicatorView.h>

#import "../PhasedStartup.h"
#import "AppStartupInstrumentation/AppStartupInstrumentation.h"
#import "NetworkInstrumentation/NetworkInstrumentation.h"
#import "AppStartupInstrumentation/System/AppStartupInstrumentationSystemUtilsImpl.h"
#import "../SpanFactory/AppStartup/AppStartupSpanFactoryImpl.h"
#import "AppStartupInstrumentation/Lifecycle/AppStartupLifecycleHandlerImpl.h"
#import "ViewLoadInstrumentation/ViewLoadInstrumentation.h"
#import "NetworkInstrumentation/System/NetworkHeaderInjector.h"
#import "../SpanFactory/AppStartup/AppStartupSpanFactory.h"
#import "../SpanFactory/ViewLoad/ViewLoadSpanFactory.h"
#import "../SpanFactory/Network/NetworkSpanFactory.h"
#import "AppStartupInstrumentation/State/AppStartupInstrumentationStateSnapshot.h"

NS_ASSUME_NONNULL_BEGIN

typedef  AppStartupInstrumentationStateSnapshot * _Nullable (^GetAppStartInstrumentationStateSnapshot)();

std::shared_ptr<AppStartupInstrumentation> createAppStartupInstrumentation(std::shared_ptr<Tracer> tracer,
                                                                           std::shared_ptr<AppStartupSpanFactory> spanFactory,
                                                                           std::shared_ptr<SpanAttributesProvider> spanAttributesProvider);

std::shared_ptr<ViewLoadInstrumentation> createViewLoadInstrumentation(std::shared_ptr<Tracer> tracer,
                                                                       std::shared_ptr<ViewLoadSpanFactory> spanFactory,
                                                                       std::shared_ptr<SpanAttributesProvider> spanAttributesProvider);

std::shared_ptr<NetworkInstrumentation> createNetworkInstrumentation(std::shared_ptr<Tracer> tracer,
                                                                     std::shared_ptr<NetworkSpanFactory> spanFactory,
                                                                     std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                                                                     std::shared_ptr<NetworkHeaderInjector> networkHeaderInjector);

namespace bugsnag {

class Instrumentation: public PhasedStartup {
public:
    Instrumentation(std::shared_ptr<Tracer> tracer,
                    std::shared_ptr<AppStartupSpanFactory> appStartupSpanFactory,
                    std::shared_ptr<ViewLoadSpanFactory> viewLoadSpanFactory,
                    std::shared_ptr<NetworkSpanFactory> networkSpanFactory,
                    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                    std::shared_ptr<NetworkHeaderInjector> networkHeaderInjector) noexcept
    : appStartupInstrumentation_(createAppStartupInstrumentation(tracer, appStartupSpanFactory, spanAttributesProvider))
    , viewLoadInstrumentation_(createViewLoadInstrumentation(tracer, viewLoadSpanFactory, spanAttributesProvider))
    , networkInstrumentation_(createNetworkInstrumentation(tracer, networkSpanFactory, spanAttributesProvider, networkHeaderInjector))
    {
        tracer->setGetAppStartInstrumentationState([=]{ return appStartupInstrumentation_->stateSnapshot(); });
    }

    void earlyConfigure(BSGEarlyConfiguration *config) noexcept;
    void earlySetup() noexcept;
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept;
    void start() noexcept;
    void abortAppStartupSpans() noexcept;

    void didStartViewLoadSpan(NSString *name) noexcept { appStartupInstrumentation_->didStartViewLoadSpan(name); }
    void willCallMainFunction() noexcept { appStartupInstrumentation_->willCallMainFunction(); }
    CFAbsoluteTime appStartDuration() noexcept { return appStartupInstrumentation_->appStartDuration(); }
    CFAbsoluteTime timeSinceAppFirstBecameActive() noexcept { return appStartupInstrumentation_->timeSinceAppFirstBecameActive(); }
    AppStartupInstrumentationStateSnapshot *getAppStartInstrumentationStateSnapshot() {
        return appStartupInstrumentation_->stateSnapshot();
    }

    void loadingIndicatorWasAdded(BugsnagPerformanceLoadingIndicatorView *loadingViewIndicator) noexcept { viewLoadInstrumentation_->loadingIndicatorWasAdded(loadingViewIndicator); }

private:
    Instrumentation() = delete;

    std::shared_ptr<class AppStartupInstrumentation> appStartupInstrumentation_;
    std::shared_ptr<class ViewLoadInstrumentation> viewLoadInstrumentation_;
    std::shared_ptr<class NetworkInstrumentation> networkInstrumentation_;
};

}

NS_ASSUME_NONNULL_END
