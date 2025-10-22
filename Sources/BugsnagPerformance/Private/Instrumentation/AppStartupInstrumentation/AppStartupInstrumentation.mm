//
//  AppStartupInstrumentation.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import "AppStartupInstrumentation.h"

#import "../../Utils/Utils.h"
#import "../../Core/Span/BugsnagPerformanceSpan+Private.h"
#import "../../Main/BugsnagPerformanceImpl.h"
#import "../../CrossTalkAPI/BugsnagPerformanceCrossTalkAPI.h"

#import <array>
#import <os/trace_base.h>
#import <sys/sysctl.h>
#import <mutex>

using namespace bugsnag;

static constexpr CFTimeInterval kMaxDuration = 120;

AppStartupInstrumentation::AppStartupInstrumentation(std::shared_ptr<AppStartupLifecycleHandler> lifecycleHandler,
                                                     std::shared_ptr<AppStartupInstrumentationSystemUtils> systemUtils) noexcept
: isEnabled_(true)
, lifecycleHandler_(lifecycleHandler)
, systemUtils_(systemUtils)
, state_([AppStartupInstrumentationState new])
{
    lifecycleHandler_->onInstrumentationInit(state_);
}

#pragma mark PhasedStartup

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

#pragma mark Lifecycle

void AppStartupInstrumentation::willCallMainFunction() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (!isEnabled_) {
        return;
    }
    
    lifecycleHandler_->onWillCallMainFunction(state_);
    startObservingNotifications();
}

void
AppStartupInstrumentation::onAppDidFinishLaunching() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (!isEnabled_) {
        return;
    }
    lifecycleHandler_->onAppDidFinishLaunching(state_);
}

void
AppStartupInstrumentation::didStartViewLoadSpan(NSString *name) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (!isEnabled_) {
        return;
    }
    lifecycleHandler_->onDidStartViewLoadSpan(state_, name);
}

void
AppStartupInstrumentation::onAppDidBecomeActive() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (!isEnabled_) {
        return;
    }
    
    lifecycleHandler_->onAppDidBecomeActive(state_);
}

#pragma mark Instrumentation cancelled

void AppStartupInstrumentation::disable() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (isEnabled_) {
        isEnabled_ = false;
        BSGLogDebug(@"AppStartupInstrumentation::disable(): Unsubscribing and canceling app start spans");
        
        stopObservingNotifications();
        lifecycleHandler_->onAppInstrumentationDisabled(state_);
    }
}

void AppStartupInstrumentation::abortAllSpans() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    lifecycleHandler_->onAppInstrumentationAborted(state_);
}

#pragma mark State access

AppStartupInstrumentationStateSnapshot *
AppStartupInstrumentation::stateSnapshot() noexcept {
    return [state_ createSnapshot];
}

CFAbsoluteTime AppStartupInstrumentation::appStartDuration() noexcept {
    CFAbsoluteTime endTime = state_.didFinishLaunchingAtTime > 0 ? state_.didFinishLaunchingAtTime : CFAbsoluteTimeGetCurrent();
    return endTime - state_.didStartProcessAtTime;
}

CFAbsoluteTime AppStartupInstrumentation::timeSinceAppFirstBecameActive() noexcept {
    if (state_.didBecomeActiveAtTime == 0) {
        return 0;
    }
    return CFAbsoluteTimeGetCurrent() - state_.didBecomeActiveAtTime;
}

#pragma mark Helpers

void
AppStartupInstrumentation::startObservingNotifications() noexcept {
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

void
AppStartupInstrumentation::stopObservingNotifications() noexcept {
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetLocalCenter(),
                                       this,
                                       CFSTR("UIApplicationDidFinishLaunchingNotification"),
                                       nullptr);
    
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetLocalCenter(),
                                       this,
                                       CFSTR("UIApplicationDidBecomeActiveNotification"),
                                       nullptr);
}

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
