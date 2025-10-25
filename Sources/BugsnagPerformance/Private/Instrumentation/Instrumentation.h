//
//  Instrumentation.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 24.04.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceLoadingIndicatorView.h>

#import "../Core/PhasedStartup.h"
#import "../Core/AppLifecycleListener.h"
#import "AppStartupInstrumentation/AppStartupInstrumentation.h"
#import "NetworkInstrumentation/NetworkInstrumentation.h"
#import "AppStartupInstrumentation/System/AppStartupInstrumentationSystemUtilsImpl.h"
#import "../Core/SpanFactory/AppStartup/AppStartupSpanFactoryImpl.h"
#import "AppStartupInstrumentation/Lifecycle/AppStartupLifecycleHandlerImpl.h"
#import "ViewLoadInstrumentation/ViewLoadInstrumentation.h"
#import "NetworkInstrumentation/System/NetworkHeaderInjector.h"
#import "../Core/SpanFactory/AppStartup/AppStartupSpanFactory.h"
#import "../Core/SpanFactory/ViewLoad/ViewLoadSpanFactory.h"
#import "../Core/SpanFactory/Network/NetworkSpanFactory.h"
#import "AppStartupInstrumentation/State/AppStartupInstrumentationStateSnapshot.h"

NS_ASSUME_NONNULL_BEGIN

typedef  AppStartupInstrumentationStateSnapshot * _Nullable (^GetAppStartInstrumentationStateSnapshot)();

namespace bugsnag {

class Instrumentation: public PhasedStartup, public AppLifecycleListener {
public:
    Instrumentation(std::shared_ptr<AppStartupInstrumentation> appStartupInstrumentation,
                    std::shared_ptr<ViewLoadInstrumentation> viewLoadInstrumentation,
                    std::shared_ptr<NetworkInstrumentation> networkInstrumentation) noexcept
    : appStartupInstrumentation_(appStartupInstrumentation)
    , viewLoadInstrumentation_(viewLoadInstrumentation)
    , networkInstrumentation_(networkInstrumentation)
    {}

    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *) noexcept {}
    void preStartSetup() noexcept {}
    void start() noexcept;
    
    void onAppFinishedLaunching() noexcept;
    void onAppEnteredBackground() noexcept;
    void onAppEnteredForeground() noexcept {}

    void didStartViewLoadSpan(NSString *name) noexcept { appStartupInstrumentation_->didStartViewLoadSpan(name); }
    void willCallMainFunction() noexcept { appStartupInstrumentation_->willCallMainFunction(); }
    AppStartupInstrumentationStateSnapshot *getAppStartInstrumentationStateSnapshot() {
        return appStartupInstrumentation_->stateSnapshot();
    }

    void loadingIndicatorWasAdded(BugsnagPerformanceLoadingIndicatorView *loadingViewIndicator) noexcept { viewLoadInstrumentation_->loadingIndicatorWasAdded(loadingViewIndicator); }

private:
    Instrumentation() = delete;
    
    bool hasCheckedAppStartDuration_{false};
    std::shared_ptr<class AppStartupInstrumentation> appStartupInstrumentation_;
    std::shared_ptr<class ViewLoadInstrumentation> viewLoadInstrumentation_;
    std::shared_ptr<class NetworkInstrumentation> networkInstrumentation_;
    
    void checkAppStartDuration() noexcept;
};

}

NS_ASSUME_NONNULL_END
