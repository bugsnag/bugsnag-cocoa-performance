//
//  AppStartupLifecycleHandlerImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 19/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "AppStartupLifecycleHandler.h"
#import "AppStartupStateValidator.h"
#import "../../../SpanFactory/AppStartup/AppStartupSpanFactory.h"
#import "../System/AppStartupInstrumentationSystemUtils.h"
#import "../../../SpanAttributesProvider.h"
#import "../../../BugsnagPerformanceCrossTalkAPI.h"

#import <memory>

@class AppInstrumentationState;

namespace bugsnag {

class AppStartupLifecycleHandlerImpl: public AppStartupLifecycleHandler {
public:
    AppStartupLifecycleHandlerImpl(std::shared_ptr<AppStartupSpanFactory> spanFactory,
                                   std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                                   std::shared_ptr<AppStartupInstrumentationSystemUtils> systemUtils,
                                   std::shared_ptr<AppStartupStateValidator> stateValidator,
                                   BugsnagPerformanceCrossTalkAPI *crossTalkAPI) noexcept;
    
    void onEarlyConfigure(AppStartupInstrumentationState *state,
                          BSGEarlyConfiguration *config) noexcept;
    void onInstrumentationInit(AppStartupInstrumentationState *state) noexcept;
    void onWillCallMainFunction(AppStartupInstrumentationState *state) noexcept;
    void onBugsnagPerformanceStarted(AppStartupInstrumentationState *state) noexcept;
    void onAppDidFinishLaunching(AppStartupInstrumentationState *state) noexcept;
    void onDidStartViewLoadSpan(AppStartupInstrumentationState *state, NSString *viewName) noexcept;
    void onAppDidBecomeActive(AppStartupInstrumentationState *state) noexcept;
    void onAppInstrumentationDisabled(AppStartupInstrumentationState *state) noexcept;
    void onAppEnteredBackground(AppStartupInstrumentationState *state) noexcept;
    void onFirstViewWillDisappear(AppStartupInstrumentationState *state) noexcept;
    
private:
    std::shared_ptr<AppStartupSpanFactory> spanFactory_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    std::shared_ptr<AppStartupInstrumentationSystemUtils> systemUtils_;
    std::shared_ptr<AppStartupStateValidator> stateValidator_;
    BugsnagPerformanceCrossTalkAPI *crossTalkAPI_;
    
    void beginAppStartSpan(AppStartupInstrumentationState *state) noexcept;
    void beginPreMainSpan(AppStartupInstrumentationState *state) noexcept;
    void beginPostMainSpan(AppStartupInstrumentationState *state) noexcept;
    void beginUIInitSpan(AppStartupInstrumentationState *state) noexcept;
    void discardAppStart(AppStartupInstrumentationState *state) noexcept;
    
    AppStartupLifecycleHandlerImpl() = delete;
};
}
