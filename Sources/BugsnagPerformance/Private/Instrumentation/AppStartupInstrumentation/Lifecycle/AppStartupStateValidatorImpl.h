//
//  AppStartupStateValidatorImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 01/12/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "AppStartupStateValidator.h"

namespace bugsnag {

class AppStartupStateValidatorImpl: public AppStartupStateValidator {
public:
    AppStartupStateValidatorImpl() noexcept {};
    ~AppStartupStateValidatorImpl() {};
    
    bool isValid(AppStartupInstrumentationState *state) noexcept;
    
private:
    bool checkInitialConditions(AppStartupInstrumentationState *state) noexcept;
    bool checkEarlyAppStartDuration(AppStartupInstrumentationState *state) noexcept;
    bool checkLaunchToActiveDuration(AppStartupInstrumentationState *state) noexcept;
    bool checkActiveToFirstBackgroundingDuration(AppStartupInstrumentationState *state) noexcept;
    CFAbsoluteTime earlyPhaseEndTime(AppStartupInstrumentationState *state) noexcept;
};
}
