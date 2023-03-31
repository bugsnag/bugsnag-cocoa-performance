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

// NOLINTBEGIN(cppcoreguidelines-avoid-non-const-global-variables)
[[clang::no_destroy]] static std::shared_ptr<AppStartupInstrumentation> instance;
// NOLINTEND(cppcoreguidelines-avoid-non-const-global-variables)

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

@interface AppStartupInstrumentation ()

@property(nonatomic,readwrite) std::shared_ptr<bugsnag::BugsnagPerformanceImpl> bugsnagPerformance;
@property(nonatomic,readwrite) CFAbsoluteTime didStartProcessAtTime;
@property(nonatomic,readwrite) CFAbsoluteTime didCallMainFunctionAtTime;
@property(nonatomic,readwrite) CFAbsoluteTime didBecomeActiveAtTime;
@property(nonatomic,readwrite) CFAbsoluteTime didFinishLaunchingAtTime;
@property(nonatomic,readwrite) bool isDisabled;
@property(nonatomic,readwrite) bool isColdLaunch;
@property(nonatomic,readwrite) bool shouldRespondToAppDidFinishLaunching;
@property(nonatomic,readwrite) bool shouldRespondToAppDidBecomeActive;
@property(nonatomic,readwrite) BugsnagPerformanceSpan *appStartSpan;
@property(nonatomic,readwrite) BugsnagPerformanceSpan *preMainSpan;
@property(nonatomic,readwrite) BugsnagPerformanceSpan *postMainSpan;
@property(nonatomic,readwrite) BugsnagPerformanceSpan *uiInitSpan;
@property(nonatomic,readwrite) NSString *firstViewName;

@end

@implementation AppStartupInstrumentation

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

// Use the constructor attribute so that this runs right before main()
// https://gcc.gnu.org/onlinedocs/gcc-4.7.0/gcc/Function-Attributes.html
// Priority is 101-65535, with higher values running later.
static void markPreMainPhase() noexcept {
    AppStartupInstrumentation *instance = [AppStartupInstrumentation sharedInstance];
    if (canInstallInstrumentation()) {
        [instance willCallMainFunction];
    } else {
        [instance disable];
    }
}

static void didFinishLaunchingCallback(CFNotificationCenterRef center,
                                       void *observer,
                                       CFNotificationName name,
                                       __unused const void *object,
                                       __unused CFDictionaryRef userInfo) noexcept {
    [[AppStartupInstrumentation sharedInstance] onAppDidFinishLaunching];
    CFNotificationCenterRemoveObserver(center, observer, name, nullptr);
}

static void didBecomeActiveCallback(CFNotificationCenterRef center,
                                                   void *observer,
                                                   CFNotificationName name,
                                                   __unused const void *object,
                                                   __unused CFDictionaryRef userInfo) noexcept {
    [[AppStartupInstrumentation sharedInstance] onAppDidBecomeActive];
    CFNotificationCenterRemoveObserver(center, observer, name, nullptr);
}

- (instancetype)init {
    if ((self = [super init])) {
        _bugsnagPerformance = getBugsnagPerformanceImpl();
        _didStartProcessAtTime = getProcessStartTime();
        _isColdLaunch = isColdLaunch();
    }
    return self;
}

//AppStartupInstrumentation::AppStartupInstrumentation()
//: bugsnagPerformance_(getBugsnagPerformanceImpl())
//, didStartProcessAtTime_(getProcessStartTime())
//, didCallMainFunctionAtTime_(CFAbsoluteTimeGetCurrent())
//, isColdLaunch_(isColdLaunch())
//{}

- (void)willCallMainFunction {
    self.didCallMainFunctionAtTime = CFAbsoluteTimeGetCurrent();

    [self beginAppStartSpan];
    [self beginPreMainSpan];
    [self.preMainSpan endWithAbsoluteTime:self.didCallMainFunctionAtTime];
    [self beginPostMainSpan];

    self.shouldRespondToAppDidBecomeActive = YES;
    self.shouldRespondToAppDidFinishLaunching = YES;
    CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(),
                                    (__bridge const void *)(self),
                                    didFinishLaunchingCallback,
                                    CFSTR("UIApplicationDidFinishLaunchingNotification"),
                                    nullptr,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(),
                                    (__bridge const void *)(self),
                                    didBecomeActiveCallback,
                                    CFSTR("UIApplicationDidBecomeActiveNotification"),
                                    nullptr,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
}

- (void)disable {
    @synchronized (self) {
        self.isDisabled = true;
        self.bugsnagPerformance->cancelQueuedSpan(self.preMainSpan);
        self.bugsnagPerformance->cancelQueuedSpan(self.postMainSpan);
        self.bugsnagPerformance->cancelQueuedSpan(self.uiInitSpan);
        self.bugsnagPerformance->cancelQueuedSpan(self.appStartSpan);
    }
}

- (void)onAppDidFinishLaunching {
    @synchronized (self) {
        if (self.isDisabled) {
            return;
        }

        if (!self.shouldRespondToAppDidFinishLaunching) {
            return;
        }
        self.shouldRespondToAppDidFinishLaunching = false;

        self.didFinishLaunchingAtTime = CFAbsoluteTimeGetCurrent();
        [self.postMainSpan endWithAbsoluteTime:self.didFinishLaunchingAtTime];
        [self beginUIInitSpan];
    }
}

- (void)didStartViewLoadSpanNamed:(NSString *)name {
    self.firstViewName = name;
}

- (void)onAppDidBecomeActive {
    @synchronized (self) {
        if (self.isDisabled) {
            return;
        }

        if (!self.shouldRespondToAppDidBecomeActive) {
            return;
        }
        self.shouldRespondToAppDidBecomeActive = false;

        self.didBecomeActiveAtTime = CFAbsoluteTimeGetCurrent();
        [self.uiInitSpan endWithAbsoluteTime:self.didBecomeActiveAtTime];
        [self.appStartSpan endWithAbsoluteTime:self.didBecomeActiveAtTime];
    }
}

- (void)beginAppStartSpan {
    if (self.isDisabled) {
        return;
    }
    if (self.appStartSpan != nullptr) {
        return;
    }

    auto name = self.isColdLaunch ? @"AppStart/Cold" : @"AppStart/Warm";
    SpanOptions options;
    options.startTime = self.didStartProcessAtTime;
    self.appStartSpan = self.bugsnagPerformance->startAppStartSpan(name, options);
    NSMutableDictionary *attributes = @{
        @"bugsnag.app_start.type": self.isColdLaunch ? @"cold" : @"warm",
        @"bugsnag.span.category": @"app_start",
    }.mutableCopy;
    if (self.firstViewName != nullptr) {
        attributes[@"bugsnag.app_start.first_view_name"] = self.firstViewName;
    }
    [self.appStartSpan addAttributes:attributes];
}

- (void)beginPreMainSpan {
    if (self.isDisabled) {
        return;
    }
    if (self.preMainSpan != nullptr) {
        return;
    }

    auto name = @"AppStartPhase/App launching - pre main()";
    SpanOptions options;
    options.startTime = self.didStartProcessAtTime;
    self.preMainSpan = self.bugsnagPerformance->startAppStartSpan(name, options);
}

- (void)beginPostMainSpan {
    if (self.isDisabled) {
        return;
    }
    if (self.postMainSpan != nullptr) {
        return;
    }

    auto name = @"AppStartPhase/App launching - post main()";
    SpanOptions options;
    options.startTime = self.didCallMainFunctionAtTime;
    self.postMainSpan = self.bugsnagPerformance->startAppStartSpan(name, options);
}

- (void)beginUIInitSpan {
    if (self.isDisabled) {
        return;
    }
    if (self.uiInitSpan != nullptr) {
        return;
    }

    auto name = @"AppStartPhase/UI init";
    SpanOptions options;
    options.startTime = self.didBecomeActiveAtTime;
    self.uiInitSpan = self.bugsnagPerformance->startAppStartSpan(name, options);
}

@end

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
