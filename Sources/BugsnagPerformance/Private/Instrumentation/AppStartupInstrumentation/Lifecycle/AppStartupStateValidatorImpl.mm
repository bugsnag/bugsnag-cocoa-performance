//
//  AppStartupStateValidatorImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 01/12/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "AppStartupStateValidatorImpl.h"

// App start spans will be thrown out if the early app start duration exceeds this.
static constexpr CFTimeInterval maxEarlyAppStartDuration = 2.0;
static constexpr CFTimeInterval maxLaunchToActiveDuration = 5.0;

// App start spans will be thrown out if the app gets backgrounded within this timeframe after starting.
static constexpr CFTimeInterval minTimeToBackgrounding = 2.0;

using namespace bugsnag;

bool
AppStartupStateValidatorImpl::isValid(AppStartupInstrumentationState *state) noexcept {
    if (state.isAborted) {
        return false;
    }
    BOOL result = true;
    switch (state.stage) {
        case BSGAppStartupStagePreMain:
            result &= checkInitialConditions(state);
            break;
        case BSGAppStartupStagePostMain:
            break;
        case BSGAppStartupStageUIInit:
            result &= checkEarlyAppStartDuration(state);
            break;
        case BSGAppStartupStageActive:
            result &= checkLaunchToActiveDuration(state);
            result &= checkActiveToFirstBackgroundingDuration(state);
            break;
    }
    return result;
}

#pragma mark Helpers

bool
AppStartupStateValidatorImpl::checkInitialConditions(AppStartupInstrumentationState *state) noexcept {
    return !state.isActivePrewarm && state.didStartProcessAtTime != 0.0;
}

bool
AppStartupStateValidatorImpl::checkEarlyAppStartDuration(AppStartupInstrumentationState *state) noexcept {
    if (state.didCheckEarlyStartDuration) {
        return true;
    }
    state.didCheckEarlyStartDuration = true;
    CFAbsoluteTime duration = earlyPhaseEndTime(state) - state.didStartProcessAtTime;
    return duration <= maxEarlyAppStartDuration;
}

bool
AppStartupStateValidatorImpl::checkLaunchToActiveDuration(AppStartupInstrumentationState *state) noexcept {
    CFAbsoluteTime duration = state.didBecomeActiveAtTime - state.didFinishLaunchingAtTime;
    return duration <= maxLaunchToActiveDuration;
}

bool
AppStartupStateValidatorImpl::checkActiveToFirstBackgroundingDuration(AppStartupInstrumentationState *state) noexcept {
    if (state.didBecomeActiveAtTime == 0.0 ||
        state.didEnterBackgroundAtTime == 0.0) {
        return true;
    }
    CFAbsoluteTime duration = state.didEnterBackgroundAtTime - state.didBecomeActiveAtTime;
    return duration >= minTimeToBackgrounding;
}

CFAbsoluteTime
AppStartupStateValidatorImpl::earlyPhaseEndTime(AppStartupInstrumentationState *state) noexcept {
    if (state.didFinishLaunchingAtTime > 0) {
        return state.didFinishLaunchingAtTime;
    }
    if (state.didStartBugsnagPerformanceAtTime > 0) {
        return state.didStartBugsnagPerformanceAtTime;
    }
    return CFAbsoluteTimeGetCurrent();
}
