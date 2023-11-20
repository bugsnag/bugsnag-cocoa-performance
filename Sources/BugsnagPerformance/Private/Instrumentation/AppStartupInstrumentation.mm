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
#import "../BugsnagPerformanceSpan+Private.h"
#import "../BugsnagPerformanceImpl.h"

#import <array>
#import <os/trace_base.h>
#import <sys/sysctl.h>
#import <mutex>

using namespace bugsnag;

static constexpr CFTimeInterval kMaxDuration = 120;

static CFAbsoluteTime getProcessStartTime() noexcept;
static bool isColdLaunch(void);
static bool canInstallInstrumentation();
// TODO: Remove after integration with Bugsnag
static uint64_t GetBootTime(void);

static inline bool isActivePrewarm(void) {
    // NOLINTNEXTLINE(concurrency-mt-unsafe)
    return getenv("ActivePrewarm") != nullptr;
}

#pragma mark -

void
AppStartupInstrumentation::didFinishLaunchingCallback(CFNotificationCenterRef center,
                                                      void *observer,
                                                      CFNotificationName name,
                                                      __unused const void *object,
                                                      __unused CFDictionaryRef userInfo) noexcept {
    auto instance = (AppStartupInstrumentation *)observer;
    instance->onAppDidFinishLaunching();
    CFNotificationCenterRemoveObserver(center, observer, name, nullptr);
}

void
AppStartupInstrumentation::didBecomeActiveCallback(CFNotificationCenterRef center,
                                                   void *observer,
                                                   CFNotificationName name,
                                                   __unused const void *object,
                                                   __unused CFDictionaryRef userInfo) noexcept {
    auto instance = (AppStartupInstrumentation *)observer;
    instance->onAppDidBecomeActive();
    CFNotificationCenterRemoveObserver(center, observer, name, nullptr);
}


AppStartupInstrumentation::AppStartupInstrumentation(std::shared_ptr<Tracer> tracer,
                                                     std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) noexcept
: isEnabled_(true)
, tracer_(tracer)
, spanAttributesProvider_(spanAttributesProvider)
, didStartProcessAtTime_(getProcessStartTime())
, didCallMainFunctionAtTime_(CFAbsoluteTimeGetCurrent())
, isColdLaunch_(isColdLaunch())
{
    if (!canInstallInstrumentation()) {
        disable();
    }
}

void AppStartupInstrumentation::configure(BugsnagPerformanceConfiguration *config) noexcept {
    if (!config.autoInstrumentAppStarts) {
        disable();
    }
}

void AppStartupInstrumentation::willCallMainFunction() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (!isEnabled_) {
        return;
    }

    beginAppStartSpan();
    beginPreMainSpan();
    [preMainSpan_ endWithAbsoluteTime:didCallMainFunctionAtTime_];
    beginPostMainSpan();

    shouldRespondToAppDidBecomeActive_ = true;
    shouldRespondToAppDidFinishLaunching_ = true;
    CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(),
                                    this,
                                    didFinishLaunchingCallback,
                                    CFSTR("UIApplicationDidFinishLaunchingNotification"),
                                    nullptr,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(),
                                    this,
                                    didBecomeActiveCallback,
                                    CFSTR("UIApplicationDidBecomeActiveNotification"),
                                    nullptr,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
}

void AppStartupInstrumentation::disable() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (isEnabled_) {
        isEnabled_ = false;
        tracer_->cancelQueuedSpan(preMainSpan_);
        tracer_->cancelQueuedSpan(postMainSpan_);
        tracer_->cancelQueuedSpan(uiInitSpan_);
        tracer_->cancelQueuedSpan(appStartSpan_);
        preMainSpan_ = nil;
        postMainSpan_ = nil;
        uiInitSpan_ = nil;
        appStartSpan_ = nil;
    }
}

void
AppStartupInstrumentation::onAppDidFinishLaunching() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (!isEnabled_) {
        return;
    }

    if (!shouldRespondToAppDidFinishLaunching_) {
        return;
    }
    shouldRespondToAppDidFinishLaunching_ = false;

    didFinishLaunchingAtTime_ = CFAbsoluteTimeGetCurrent();
    [postMainSpan_ endWithAbsoluteTime:didFinishLaunchingAtTime_];
    beginUIInitSpan();

}

void
AppStartupInstrumentation::didStartViewLoadSpan(NSString *name) noexcept {
    firstViewName_ = name;
}

void
AppStartupInstrumentation::onAppDidBecomeActive() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (!isEnabled_) {
        return;
    }

    if (!shouldRespondToAppDidBecomeActive_) {
        return;
    }
    shouldRespondToAppDidBecomeActive_ = false;

    didBecomeActiveAtTime_ = CFAbsoluteTimeGetCurrent();
    [uiInitSpan_ endWithAbsoluteTime:didBecomeActiveAtTime_];
    [appStartSpan_ endWithAbsoluteTime:didBecomeActiveAtTime_];
}

void
AppStartupInstrumentation::beginAppStartSpan() noexcept {
    if (!isEnabled_) {
        return;
    }
    if (appStartSpan_ != nullptr) {
        return;
    }

    auto name = isColdLaunch_ ? @"[AppStart/iOSCold]" : @"[AppStart/iOSWarm]";
    SpanOptions options;
    options.startTime = didStartProcessAtTime_;
    appStartSpan_ = tracer_->startAppStartSpan(name, options);
    [appStartSpan_ addAttributes:spanAttributesProvider_->appStartSpanAttributes(firstViewName_, isColdLaunch_)];
}

void
AppStartupInstrumentation::beginPreMainSpan() noexcept {
    if (!isEnabled_) {
        return;
    }
    if (preMainSpan_ != nullptr) {
        return;
    }

    auto name = @"[AppStartPhase/App launching - pre main()]";
    SpanOptions options;
    options.startTime = didStartProcessAtTime_;
    options.parentContext = appStartSpan_;
    preMainSpan_ = tracer_->startAppStartSpan(name, options);
    [preMainSpan_ addAttributes:spanAttributesProvider_->appStartPhaseSpanAttributes(@"App launching - pre main()")];
}

void
AppStartupInstrumentation::beginPostMainSpan() noexcept {
    if (!isEnabled_) {
        return;
    }
    if (postMainSpan_ != nullptr) {
        return;
    }

    auto name = @"[AppStartPhase/App launching - post main()]";
    SpanOptions options;
    options.startTime = didCallMainFunctionAtTime_;
    options.parentContext = appStartSpan_;
    postMainSpan_ = tracer_->startAppStartSpan(name, options);
    [postMainSpan_ addAttributes:spanAttributesProvider_->appStartPhaseSpanAttributes(@"App launching - post main()")];
}

void
AppStartupInstrumentation::beginUIInitSpan() noexcept {
    if (!isEnabled_) {
        return;
    }
    if (uiInitSpan_ != nullptr) {
        return;
    }

    auto name = @"[AppStartPhase/UI init]";
    SpanOptions options;
    options.startTime = didFinishLaunchingAtTime_;
    options.parentContext = appStartSpan_;
    uiInitSpan_ = tracer_->startAppStartSpan(name, options);
    [uiInitSpan_ addAttributes:spanAttributesProvider_->appStartPhaseSpanAttributes(@"UI init")];
}

#pragma mark -

static CFAbsoluteTime getProcessStartTime() noexcept {
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

static bool isColdLaunch(void) {
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

static bool canInstallInstrumentation() {
    if (isActivePrewarm()) {
        BSGLogInfo(@"App startup instrumentation disabled due to ActivePrewarm");
        return false;
    }
    auto processStartTime = getProcessStartTime();
    if (processStartTime == 0.0) {
        BSGLogInfo(@"App startup instrumentation disabled because process start time is 0");
        return false;
    }
    if (CFAbsoluteTimeGetCurrent() > processStartTime + kMaxDuration) {
        BSGLogWarning(@"Ignoring excessively long app startup span");
        return false;
    }
    return true;
}
