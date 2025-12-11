//
//  AppStartupLifecycleHandlerImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 19/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "AppStartupLifecycleHandlerImpl.h"
#import "../../../SpanFactory/AppStartup/AppStartupSpanFactory.h"
#import "../../../SpanAttributesProvider.h"
#import "../../../BugsnagPerformanceSpan+Private.h"

using namespace bugsnag;

static constexpr CGFloat kFirstViewDelayThreshold = 1.5;

static bool isAppStartInProgress(AppStartupInstrumentationState *state) noexcept {
    return state.appStartSpan != nil && (state.appStartSpan.isValid || state.appStartSpan.isBlocked);
}

AppStartupLifecycleHandlerImpl::AppStartupLifecycleHandlerImpl(std::shared_ptr<AppStartupSpanFactory> spanFactory,
                                                               std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                                                               std::shared_ptr<AppStartupInstrumentationSystemUtils> systemUtils,
                                                               std::shared_ptr<AppStartupStateValidator> stateValidator,
                                                               BugsnagPerformanceCrossTalkAPI *crossTalkAPI) noexcept
: spanFactory_(spanFactory)
, spanAttributesProvider_(spanAttributesProvider)
, systemUtils_(systemUtils)
, stateValidator_(stateValidator)
, crossTalkAPI_(crossTalkAPI) {}

#pragma mark Lifecycle

void
AppStartupLifecycleHandlerImpl::onEarlyConfigure(AppStartupInstrumentationState *state,
                                                 BSGEarlyConfiguration *config) noexcept {
    state.didStartEarlyPhaseAtTime = config.earlyPhaseStartTime;
}

void
AppStartupLifecycleHandlerImpl::onInstrumentationInit(AppStartupInstrumentationState *state) noexcept {
    state.isActivePrewarm = systemUtils_->isActivePrewarm();
    state.didStartProcessAtTime = systemUtils_->getProcessStartTime();
    state.isColdLaunch = systemUtils_->isColdLaunch();
    state.stage = BSGAppStartupStagePreMain;
    if (!stateValidator_->isValid(state)) {
        discardAppStart(state);
        return;
    }
}

void
AppStartupLifecycleHandlerImpl::onWillCallMainFunction(AppStartupInstrumentationState *state) noexcept {
    if (state.isDiscarded) {
        return;
    }
    beginAppStartSpan(state);
    beginPreMainSpan(state);
    state.didCallMainFunctionAtTime = CFAbsoluteTimeGetCurrent();
    [state.preMainSpan endWithAbsoluteTime:state.didCallMainFunctionAtTime];
    beginPostMainSpan(state);
    state.stage = BSGAppStartupStagePostMain;
    if (!stateValidator_->isValid(state)) {
        discardAppStart(state);
        return;
    }

    state.shouldRespondToAppDidBecomeActive = true;
    state.shouldRespondToAppDidFinishLaunching = true;
}

void
AppStartupLifecycleHandlerImpl::onBugsnagPerformanceStarted(AppStartupInstrumentationState *state) noexcept {
    if (state.isDiscarded) {
        return;
    }
    state.didStartBugsnagPerformanceAtTime = CFAbsoluteTimeGetCurrent();
    if (!stateValidator_->isValid(state)) {
        discardAppStart(state);
    }
}

void
AppStartupLifecycleHandlerImpl::onAppDidFinishLaunching(AppStartupInstrumentationState *state) noexcept {
    if (state.isDiscarded ||
        !state.shouldRespondToAppDidFinishLaunching) {
        return;
    }
    state.shouldRespondToAppDidFinishLaunching = false;
    state.didFinishLaunchingAtTime = CFAbsoluteTimeGetCurrent();
    [state.postMainSpan endWithAbsoluteTime:state.didFinishLaunchingAtTime];
    beginUIInitSpan(state);
    state.stage = BSGAppStartupStageUIInit;
    if (!stateValidator_->isValid(state)) {
        discardAppStart(state);
    }
}

void
AppStartupLifecycleHandlerImpl::onDidStartViewLoadSpan(AppStartupInstrumentationState *state, NSString *viewName) noexcept {
    if (state.isDiscarded) {
        return;
    }
    if (state.firstViewName == nil) {
        state.firstViewName = viewName;
        if (isAppStartInProgress(state)) {
            [state.appStartSpan internalSetMultipleAttributes:spanAttributesProvider_->appStartSpanAttributes(state.firstViewName, state.isColdLaunch)];
        }
    }
}

void
AppStartupLifecycleHandlerImpl::onAppDidBecomeActive(AppStartupInstrumentationState *state) noexcept {
    if (state.isDiscarded ||
        !state.shouldRespondToAppDidBecomeActive) {
        return;
    }
    state.shouldRespondToAppDidBecomeActive = false;

    state.didBecomeActiveAtTime = CFAbsoluteTimeGetCurrent();
    state.stage = BSGAppStartupStageActive;
    if (!stateValidator_->isValid(state)) {
        discardAppStart(state);
        return;
    }
    
    [crossTalkAPI_ willEndUIInitSpan:state.uiInitSpan];
    [state.appStartSpan endWithAbsoluteTime:state.didBecomeActiveAtTime];
    if (state.firstViewName == nil) {
        [state.uiInitSpan blockWithTimeout:kFirstViewDelayThreshold];
    }
    [state.uiInitSpan endWithAbsoluteTime:state.didBecomeActiveAtTime];
}

void
AppStartupLifecycleHandlerImpl::onAppEnteredBackground(AppStartupInstrumentationState *state) noexcept {
    if (state.didEnterBackgroundAtTime == 0.0) {
        state.didEnterBackgroundAtTime = CFAbsoluteTimeGetCurrent();
    }
    if (!stateValidator_->isValid(state)) {
        discardAppStart(state);
    }
}

void
AppStartupLifecycleHandlerImpl::onFirstViewWillDisappear(AppStartupInstrumentationState *state) noexcept {
    state.calledFirstViewWillDisappear = true;
    if (!stateValidator_->isValid(state)) {
        discardAppStart(state);
    }
}

#pragma mark Instrumentation cancelled

void
AppStartupLifecycleHandlerImpl::onAppInstrumentationDisabled(AppStartupInstrumentationState *state) noexcept {
    [state.preMainSpan cancel];
    [state.postMainSpan cancel];
    [state.uiInitSpan cancel];
    [state.appStartSpan cancel];
    state.preMainSpan = nil;
    state.postMainSpan = nil;
    state.uiInitSpan = nil;
    state.appStartSpan = nil;
}

#pragma mark Helpers

void
AppStartupLifecycleHandlerImpl::beginAppStartSpan(AppStartupInstrumentationState *state) noexcept {
    if (state.appStartSpan != nullptr) {
        return;
    }

    state.appStartSpan = spanFactory_->startAppStartOverallSpan(state.didStartProcessAtTime,
                                                                state.isColdLaunch,
                                                                state.firstViewName);
}

void
AppStartupLifecycleHandlerImpl::beginPreMainSpan(AppStartupInstrumentationState *state) noexcept {
    if (state.preMainSpan != nullptr) {
        return;
    }

    state.preMainSpan = spanFactory_->startPreMainSpan(state.didStartProcessAtTime, state.appStartSpan);
}

void
AppStartupLifecycleHandlerImpl::beginPostMainSpan(AppStartupInstrumentationState *state) noexcept {
    if (state.postMainSpan != nullptr) {
        return;
    }

    state.postMainSpan = spanFactory_->startPostMainSpan(state.didCallMainFunctionAtTime, state.appStartSpan);
}

void
AppStartupLifecycleHandlerImpl::beginUIInitSpan(AppStartupInstrumentationState *state) noexcept {
    if (state.uiInitSpan != nullptr) {
        return;
    }
    
    BugsnagPerformanceSpanCondition *appStartCondition = [state.appStartSpan blockWithTimeout:0.1];
    NSArray *conditionsToEndOnClose = @[];
    if (appStartCondition) {
        conditionsToEndOnClose = @[appStartCondition];
    }

    state.uiInitSpan = spanFactory_->startUIInitSpan(state.didFinishLaunchingAtTime, state.appStartSpan, conditionsToEndOnClose);
}

void
AppStartupLifecycleHandlerImpl::discardAppStart(AppStartupInstrumentationState *state) noexcept {
    [state.preMainSpan abortUnconditionally];
    [state.postMainSpan abortUnconditionally];
    [state.uiInitSpan abortUnconditionally];
    [state.appStartSpan abortUnconditionally];
    state.isDiscarded = true;
}
