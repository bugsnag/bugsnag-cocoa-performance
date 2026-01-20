//
//  AppStartupInstrumentationSystemUtils.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 18/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <os/trace_base.h>
#import <sys/sysctl.h>

namespace bugsnag {

class AppStartupInstrumentationSystemUtils {
public:
    virtual CFAbsoluteTime getProcessStartTime() noexcept = 0;
    virtual bool isActivePrewarm() noexcept = 0;
    virtual bool isColdLaunch(void) = 0;
    virtual uint64_t GetBootTime(void) = 0;
    virtual ~AppStartupInstrumentationSystemUtils() {}
};
}
