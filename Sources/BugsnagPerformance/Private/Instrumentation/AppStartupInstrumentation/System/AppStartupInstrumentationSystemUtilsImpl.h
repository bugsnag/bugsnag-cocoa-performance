//
//  AppStartupInstrumentationSystemUtils.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 18/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "AppStartupInstrumentationSystemUtils.h"

namespace bugsnag {

class AppStartupInstrumentationSystemUtilsImpl: public AppStartupInstrumentationSystemUtils {
public:
    CFAbsoluteTime getProcessStartTime() noexcept;
    bool isColdLaunch(void);
    bool canInstallInstrumentation(CFTimeInterval maxDuration);
    uint64_t GetBootTime(void);
};
}
