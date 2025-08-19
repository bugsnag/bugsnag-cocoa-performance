//
//  AppStartupInstrumentation.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import "AppStartupInstrumentation.h"

#import "../../Tracer.h"
#import "../../Utils.h"
#import "../../BugsnagPerformanceSpan+Private.h"
#import "../../BugsnagPerformanceImpl.h"
#import "../../BugsnagPerformanceCrossTalkAPI.h"

#import <array>
#import <os/trace_base.h>
#import <sys/sysctl.h>
#import <mutex>

using namespace bugsnag;

static constexpr CFTimeInterval kMaxDuration = 120;
static constexpr CGFloat kFirstViewDelayThreshold = 1.5;

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
                                                     std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                                                     std::shared_ptr<AppStartupInstrumentationSystemUtils> systemUtils) noexcept
: isEnabled_(true)
, tracer_(tracer)
, spanAttributesProvider_(spanAttributesProvider)
, systemUtils_(systemUtils)
, didStartProcessAtTime_(systemUtils->getProcessStartTime())
, isColdLaunch_(systemUtils->isColdLaunch())
{
    tracer_->setGetAppStartInstrumentationState([=]{ return instrumentationState(); });
}

void AppStartupInstrumentation::earlySetup() noexcept {
    if (!systemUtils_->canInstallInstrumentation(kMaxDuration)) {
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
    didCallMainFunctionAtTime_ = CFAbsoluteTimeGetCurrent();
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
        BSGLogDebug(@"AppStartupInstrumentation::disable(): Canceling app start spans");
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

CFAbsoluteTime AppStartupInstrumentation::appStartDuration() noexcept {
    CFAbsoluteTime endTime = didFinishLaunchingAtTime_ > 0 ? didFinishLaunchingAtTime_ : CFAbsoluteTimeGetCurrent();
    return endTime - didStartProcessAtTime_;
}

CFAbsoluteTime AppStartupInstrumentation::timeSinceAppFirstBecameActive() noexcept {
    if (didBecomeActiveAtTime_ == 0) {
        return 0;
    }
    return CFAbsoluteTimeGetCurrent() - didBecomeActiveAtTime_;
}

void AppStartupInstrumentation::abortAllSpans() noexcept {
    [preMainSpan_ abortUnconditionally];
    [postMainSpan_ abortUnconditionally];
    [uiInitSpan_ abortUnconditionally];
    [appStartSpan_ abortUnconditionally];
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
    if (firstViewName_ == nil) {
        firstViewName_ = name;
        if (isAppStartInProgress()) {
            [appStartSpan_ internalSetMultipleAttributes:spanAttributesProvider_->appStartSpanAttributes(firstViewName_, isColdLaunch_)];
        }
    }
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
    [[BugsnagPerformanceCrossTalkAPI sharedInstance] willEndUIInitSpan:uiInitSpan_];
    [appStartSpan_ endWithAbsoluteTime:didBecomeActiveAtTime_];
    if (firstViewName_ == nil) {
        [uiInitSpan_ blockWithTimeout:kFirstViewDelayThreshold];
    }
    [uiInitSpan_ endWithAbsoluteTime:didBecomeActiveAtTime_];
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
    appStartSpan_ = tracer_->startAppStartSpan(name, options, @[]);
    [appStartSpan_ internalSetMultipleAttributes:spanAttributesProvider_->appStartSpanAttributes(firstViewName_, isColdLaunch_)];
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
    preMainSpan_ = tracer_->startAppStartSpan(name, options, @[]);
    [preMainSpan_ internalSetMultipleAttributes:spanAttributesProvider_->appStartPhaseSpanAttributes(@"App launching - pre main()")];
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
    postMainSpan_ = tracer_->startAppStartSpan(name, options, @[]);
    [postMainSpan_ internalSetMultipleAttributes:spanAttributesProvider_->appStartPhaseSpanAttributes(@"App launching - post main()")];
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
    BugsnagPerformanceSpanCondition *appStartCondition = [appStartSpan_ blockWithTimeout:0.1];
    NSArray *conditionsToEndOnClose = @[];
    if (appStartCondition) {
        conditionsToEndOnClose = @[appStartCondition];
    }
    uiInitSpan_ = tracer_->startAppStartSpan(name, options, conditionsToEndOnClose);
    [uiInitSpan_ internalSetMultipleAttributes:spanAttributesProvider_->appStartPhaseSpanAttributes(@"UI init")];
}

AppStartupInstrumentationState *
AppStartupInstrumentation::instrumentationState() noexcept {
    auto state = [AppStartupInstrumentationState new];
    state.appStartSpan = appStartSpan_;
    state.preMainSpan = preMainSpan_;
    state.postMainSpan = postMainSpan_;
    state.uiInitSpan = uiInitSpan_;
    state.hasFirstView = firstViewName_ != nil;
    state.isInProgress = uiInitSpan_.isValid || uiInitSpan_.isBlocked;
    return state;
}

bool
AppStartupInstrumentation::isAppStartInProgress() noexcept {
    return appStartSpan_ != nil && (appStartSpan_.isValid || appStartSpan_.isBlocked);
}
