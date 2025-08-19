//
//  Instrumentation.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 24.04.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import "../PhasedStartup.h"
#import "../Instrumentation/AppStartupInstrumentation/AppStartupInstrumentation.h"
#import "../Instrumentation/NetworkInstrumentation/NetworkInstrumentation.h"
#import "../Instrumentation/ViewLoadInstrumentation/ViewLoadInstrumentation.h"
#import "../Instrumentation/AppStartupInstrumentation/System/AppStartupInstrumentationSystemUtilsImpl.h"
#import "../Instrumentation/AppStartupInstrumentation/SpanFactory/AppStartupSpanFactoryImpl.h"

namespace bugsnag {

class Instrumentation: public PhasedStartup {
public:
    Instrumentation(std::shared_ptr<Tracer> tracer,
                    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                    std::shared_ptr<NetworkHeaderInjector> networkHeaderInjector) noexcept
    : appStartupInstrumentation_(std::make_shared<AppStartupInstrumentation>(std::make_shared<AppStartupSpanFactoryImpl>(tracer, spanAttributesProvider), std::make_shared<AppStartupInstrumentationSystemUtilsImpl>()))
    , viewLoadInstrumentation_(std::make_shared<ViewLoadInstrumentation>(tracer, spanAttributesProvider))
    , networkInstrumentation_(std::make_shared<NetworkInstrumentation>(tracer,
                                                                       spanAttributesProvider,
                                                                       networkHeaderInjector))
    {}

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
