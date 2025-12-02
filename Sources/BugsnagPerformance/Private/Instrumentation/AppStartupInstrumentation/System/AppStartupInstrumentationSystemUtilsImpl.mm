//
//  AppStartupInstrumentationSystemUtils.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 18/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "AppStartupInstrumentationSystemUtilsImpl.h"
#import "../../../Utils.h"

#import <array>

using namespace bugsnag;

CFAbsoluteTime
AppStartupInstrumentationSystemUtilsImpl::getProcessStartTime() noexcept {
    std::array<int, 4> cmd { CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid() };
    struct kinfo_proc info = {{{{0}}}};
    auto size = sizeof info;
    
    if (sysctl(cmd.data(), cmd.size(), &info, &size, NULL, 0)) {
        return 0.0;
    }
    
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-union-access)
    auto timeval = info.kp_proc.p_un.__p_starttime;
    return timevalToAbsoluteTime(timeval);
}

bool
AppStartupInstrumentationSystemUtilsImpl::isActivePrewarm() noexcept {
    // NOLINTNEXTLINE(concurrency-mt-unsafe)
    return getenv("ActivePrewarm") != nullptr;
}

// TODO: Remove after integration with Bugsnag
uint64_t
AppStartupInstrumentationSystemUtilsImpl::GetBootTime(void) {
    struct timeval tv;
    size_t len = sizeof(tv);
    int ret = sysctl((int[]){CTL_KERN, KERN_BOOTTIME}, 2, &tv, &len, NULL, 0);
    if (ret == -1) return 0;
    return (uint64_t)tv.tv_sec * USEC_PER_SEC + (uint64_t)tv.tv_usec;
}

bool
AppStartupInstrumentationSystemUtilsImpl::isColdLaunch(void) {
    //
    // The launch ID is used to detect when the app has been upgraded or the
    // device rebooted, which would definitely result in a cold launch.
    // There doesn't appear to be a way to positively identify warm launches
    // (those where the app's binary images were still mapped in memory).
    //
    // TODO: Use BSGRunContext.machoUUID and BSGRunContext.bootTime
    auto launchId = [NSString stringWithFormat:@"%@/%llu",
                     NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"],
                     GetBootTime()];

    auto launchIdKey = @"BugsnagPerformanceLaunchId";
    auto userDefaults = [NSUserDefaults standardUserDefaults];
    bool isCold = ![[userDefaults stringForKey:launchIdKey] isEqualToString:launchId];
    [userDefaults setObject:launchId forKey:launchIdKey];
    return isCold;
}
