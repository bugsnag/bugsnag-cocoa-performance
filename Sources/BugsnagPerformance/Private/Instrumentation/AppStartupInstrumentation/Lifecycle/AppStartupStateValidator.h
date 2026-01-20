//
//  AppStartupStateValidator.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 01/12/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import "../State/AppStartupInstrumentationState.h"

namespace bugsnag {

class AppStartupStateValidator {
public:
    virtual bool isValid(AppStartupInstrumentationState *state) noexcept = 0;
    virtual ~AppStartupStateValidator() {}
};
}
