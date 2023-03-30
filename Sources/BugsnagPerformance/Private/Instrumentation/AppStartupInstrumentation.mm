//
//  AppStartupInstrumentation.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import "AppStartupInstrumentation.h"

#import "../Span.h"
#import "../Tracer.h"
#import "../Utils.h"

#import <array>
#import <os/trace_base.h>
#import <sys/sysctl.h>

using namespace bugsnag;

static constexpr CFTimeInterval kMaxDuration = 120;

// NOLINTBEGIN(cppcoreguidelines-avoid-non-const-global-variables)
static AppStartupInstrumentation *instance;
static CFAbsoluteTime didBecomeActive;
// NOLINTEND(cppcoreguidelines-avoid-non-const-global-variables)

static inline bool ActivePrewarm(void) {
    // NOLINTNEXTLINE(concurrency-mt-unsafe)
    return getenv("ActivePrewarm") != nullptr;
}

// TODO: Remove after integration with Bugsnag
static uint64_t GetBootTime(void);

void
AppStartupInstrumentation::initialize() noexcept {
    if (ActivePrewarm()) {
        return;
    }
    
    CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(),
                                    &didBecomeActive, // arbitrary pointer to allow later removal
                                    notificationCallback,
                                    CFSTR("UIApplicationDidBecomeActiveNotification"),
                                    nullptr,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
}

void
AppStartupInstrumentation::start() noexcept {
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
    isCold_ = ![[userDefaults stringForKey:launchIdKey] isEqualToString:launchId];
    [userDefaults setObject:launchId forKey:launchIdKey];
    
    if (ActivePrewarm()) {
        BSGLogInfo(@"App startup instrumentation disabled due to ActivePrewarm");
    } else if (didBecomeActive != 0) {
        // App is already active
        reportSpan(didBecomeActive);
    } else {
        instance = this;
    }
    firstViewName_ = nullptr;
}

void
AppStartupInstrumentation::didStartViewLoadSpan(NSString *name) noexcept {
    if (firstViewName_ == nullptr) {
        firstViewName_ = name;
    }
}

void
AppStartupInstrumentation::notificationCallback(CFNotificationCenterRef center,
                                                void *observer,
                                                CFNotificationName name,
                                                __unused const void *object,
                                                __unused CFDictionaryRef userInfo) noexcept {
    didBecomeActive = CFAbsoluteTimeGetCurrent();
    if (instance) {
        instance->reportSpan(didBecomeActive);
        instance = nullptr;
    }
    CFNotificationCenterRemoveObserver(center, observer, name, nullptr);
}

void
AppStartupInstrumentation::reportSpan(CFAbsoluteTime endTime) noexcept {
    auto startTime = getProcessStartTime();
    if (startTime == 0.0) {
        return;
    }
    if (endTime > startTime + kMaxDuration) {
        BSGLogWarning(@"Ignoring excessively long app startup span");
        return;
    }
    auto name = isCold_ ? @"AppStart/Cold" : @"AppStart/Warm";
    auto options = defaultSpanOptionsForInternal();
    options.startTime = startTime;
    auto span = tracer_.startSpan(name, options, BSGFirstClassUnset);
    NSMutableDictionary *attributes = @{
        @"bugsnag.app_start.type": isCold_ ? @"cold" : @"warm",
        @"bugsnag.span.category": @"app_start",
    }.mutableCopy;
    if (firstViewName_ != nullptr) {
        attributes[@"bugsnag.app_start.first_view_name"] = firstViewName_;
    }
    span->addAttributes(attributes);
    span->end(endTime);
}

CFAbsoluteTime
AppStartupInstrumentation::getProcessStartTime() noexcept {
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

// TODO: Remove after integration with Bugsnag
static uint64_t GetBootTime(void) {
    struct timeval tv;
    size_t len = sizeof(tv);
    int ret = sysctl((int[]){CTL_KERN, KERN_BOOTTIME}, 2, &tv, &len, NULL, 0);
    if (ret == -1) return 0;
    return (uint64_t)tv.tv_sec * USEC_PER_SEC + (uint64_t)tv.tv_usec;
}
