//
//  AppStartupLifecycleHandlerImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 19/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "AppStartupLifecycleHandler.h"
#import "../SpanFactory/AppStartupSpanFactory.h"
#import "../System/AppStartupInstrumentationSystemUtils.h"
#import "../../../SpanAttributesProvider.h"
#import "../../../BugsnagPerformanceCrossTalkAPI.h"
#import "../../../Tracer.h"

#import <memory>

@class AppInstrumentationState;

namespace bugsnag {

class AppStartupLifecycleHandlerImpl: public AppStartupLifecycleHandler {
public:
    AppStartupLifecycleHandlerImpl(std::shared_ptr<AppStartupSpanFactory> spanFactory,
                                   std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                                   std::shared_ptr<Tracer> tracer,
                                   std::shared_ptr<AppStartupInstrumentationSystemUtils> systemUtils,
                                   BugsnagPerformanceCrossTalkAPI *crossTalkAPI) noexcept;
    
    void onInstrumentationInit(AppStartupInstrumentationState *state) noexcept;
    void onWillCallMainFunction(AppStartupInstrumentationState *state) noexcept;
    void onAppDidFinishLaunching(AppStartupInstrumentationState *state) noexcept;
    void onDidStartViewLoadSpan(AppStartupInstrumentationState *state, NSString *viewName) noexcept;
    void onAppDidBecomeActive(AppStartupInstrumentationState *state) noexcept;
    void onAppInstrumentationDisabled(AppStartupInstrumentationState *state) noexcept;
    void onAppInstrumentationAborted(AppStartupInstrumentationState *state) noexcept;
    
private:
    std::shared_ptr<AppStartupSpanFactory> spanFactory_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    std::shared_ptr<Tracer> tracer_;
    std::shared_ptr<AppStartupInstrumentationSystemUtils> systemUtils_;
    BugsnagPerformanceCrossTalkAPI *crossTalkAPI_;
    
    void beginAppStartSpan(AppStartupInstrumentationState *state) noexcept;
    void beginPreMainSpan(AppStartupInstrumentationState *state) noexcept;
    void beginPostMainSpan(AppStartupInstrumentationState *state) noexcept;
    void beginUIInitSpan(AppStartupInstrumentationState *state) noexcept;
    
    AppStartupLifecycleHandlerImpl() = delete;
};
}
