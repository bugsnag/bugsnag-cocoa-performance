//
//  Instrumentation.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 24.04.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import "../PhasedStartup.h"
#import "AppStartupInstrumentation/AppStartupInstrumentation.h"
#import "NetworkInstrumentation/NetworkInstrumentation.h"
#import "AppStartupInstrumentation/System/AppStartupInstrumentationSystemUtilsImpl.h"
#import "AppStartupInstrumentation/SpanFactory/AppStartupSpanFactoryImpl.h"
#import "AppStartupInstrumentation/Lifecycle/AppStartupLifecycleHandlerImpl.h"
#import "ViewLoadInstrumentation/ViewLoadInstrumentation.h"
#import "NetworkInstrumentation/System/NetworkHeaderInjector.h"

std::shared_ptr<ViewLoadInstrumentation> createViewLoadInstrumentation(std::shared_ptr<Tracer> tracer,
                                                                       std::shared_ptr<SpanAttributesProvider> spanAttributesProvider);

std::shared_ptr<NetworkInstrumentation> createNetworkInstrumentation(std::shared_ptr<Tracer> tracer,
                                                                     std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                                                                     std::shared_ptr<NetworkHeaderInjector> networkHeaderInjector);

namespace bugsnag {

class Instrumentation: public PhasedStartup {
public:
    Instrumentation(std::shared_ptr<Tracer> tracer,
                    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                    std::shared_ptr<NetworkHeaderInjector> networkHeaderInjector) noexcept
    : appStartupInstrumentation_(std::make_shared<AppStartupInstrumentation>(std::make_shared<AppStartupLifecycleHandlerImpl>(std::make_shared<AppStartupSpanFactoryImpl>(tracer, spanAttributesProvider), spanAttributesProvider, tracer, std::make_shared<AppStartupInstrumentationSystemUtilsImpl>(), [BugsnagPerformanceCrossTalkAPI sharedInstance]), std::make_shared<AppStartupInstrumentationSystemUtilsImpl>()))
    , viewLoadInstrumentation_(createViewLoadInstrumentation(tracer, spanAttributesProvider))
    , networkInstrumentation_(createNetworkInstrumentation(tracer, spanAttributesProvider, networkHeaderInjector))
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

private:
    Instrumentation() = delete;

    std::shared_ptr<class AppStartupInstrumentation> appStartupInstrumentation_;
    std::shared_ptr<class ViewLoadInstrumentation> viewLoadInstrumentation_;
    std::shared_ptr<class NetworkInstrumentation> networkInstrumentation_;
};

}
