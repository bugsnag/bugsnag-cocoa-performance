//
//  AppStartupLifecycleHandler.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 19/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import "../State/AppStartupInstrumentationState.h"
#import "../../../EarlyConfiguration.h"

namespace bugsnag {

class AppStartupLifecycleHandler {
public:
    virtual void onEarlyConfigure(AppStartupInstrumentationState *state,
                                  BSGEarlyConfiguration *config) noexcept = 0;
    virtual void onConfigure(AppStartupInstrumentationState *state,
                             BugsnagPerformanceConfiguration *config) noexcept = 0;
    virtual void onInstrumentationInit(AppStartupInstrumentationState *state) noexcept = 0;
    virtual void onWillCallMainFunction(AppStartupInstrumentationState *state) noexcept = 0;
    virtual void onBugsnagPerformanceStarted(AppStartupInstrumentationState *state) noexcept = 0;
    virtual void onAppDidFinishLaunching(AppStartupInstrumentationState *state) noexcept = 0;
    virtual void onDidStartViewLoadSpan(AppStartupInstrumentationState *state, NSString *viewName) noexcept = 0;
    virtual void onAppDidBecomeActive(AppStartupInstrumentationState *state) noexcept = 0;
    virtual void onAppInstrumentationDisabled(AppStartupInstrumentationState *state) noexcept = 0;
    virtual void onAppEnteredBackground(AppStartupInstrumentationState *state) noexcept = 0;
    virtual void onFirstViewWillDisappear(AppStartupInstrumentationState *state) noexcept = 0;
    virtual ~AppStartupLifecycleHandler() {}
};
}
