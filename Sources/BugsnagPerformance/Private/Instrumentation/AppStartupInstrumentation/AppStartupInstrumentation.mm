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


AppStartupInstrumentation::AppStartupInstrumentation(std::shared_ptr<AppStartupSpanFactory> spanFactory,
                                                     std::shared_ptr<AppStartupInstrumentationSystemUtils> systemUtils) noexcept
: isEnabled_(true)
, spanFactory_(spanFactory)
, systemUtils_(systemUtils)
, state_([AppStartupInstrumentationState new])
{
    state_.didStartProcessAtTime = systemUtils->getProcessStartTime();
    state_.isColdLaunch = systemUtils->isColdLaunch();
    // TODO: Reintroduce
    // tracer_->setGetAppStartInstrumentationState([=]{ return instrumentationState(); });
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
    state_.didCallMainFunctionAtTime = CFAbsoluteTimeGetCurrent();
    [state_.preMainSpan endWithAbsoluteTime:state_.didCallMainFunctionAtTime];
    beginPostMainSpan();

    state_.shouldRespondToAppDidBecomeActive = true;
    state_.shouldRespondToAppDidFinishLaunching = true;
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
        
        // TODO: Reintroduce
//        tracer_->cancelQueuedSpan(preMainSpan_);
//        tracer_->cancelQueuedSpan(postMainSpan_);
//        tracer_->cancelQueuedSpan(uiInitSpan_);
//        tracer_->cancelQueuedSpan(appStartSpan_);
        state_.preMainSpan = nil;
        state_.postMainSpan = nil;
        state_.uiInitSpan = nil;
        state_.appStartSpan = nil;
    }
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

void AppStartupInstrumentation::abortAllSpans() noexcept {
    [state_.preMainSpan abortUnconditionally];
    [state_.postMainSpan abortUnconditionally];
    [state_.uiInitSpan abortUnconditionally];
    [state_.appStartSpan abortUnconditionally];
}

void
AppStartupInstrumentation::onAppDidFinishLaunching() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (!isEnabled_) {
        return;
    }

    if (!state_.shouldRespondToAppDidFinishLaunching) {
        return;
    }
    state_.shouldRespondToAppDidFinishLaunching = false;

    state_.didFinishLaunchingAtTime = CFAbsoluteTimeGetCurrent();
    [state_.postMainSpan endWithAbsoluteTime:state_.didFinishLaunchingAtTime];
    beginUIInitSpan();

}

void
AppStartupInstrumentation::didStartViewLoadSpan(NSString *name) noexcept {
    if (state_.firstViewName == nil) {
        state_.firstViewName = name;
        if (isAppStartInProgress()) {
            // TODO: Reintroduce
//            [appStartSpan_ internalSetMultipleAttributes:spanAttributesProvider_->appStartSpanAttributes(firstViewName_, isColdLaunch_)];
        }
    }
}

void
AppStartupInstrumentation::onAppDidBecomeActive() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (!isEnabled_) {
        return;
    }

    if (!state_.shouldRespondToAppDidBecomeActive) {
        return;
    }
    state_.shouldRespondToAppDidBecomeActive = false;

    state_.didBecomeActiveAtTime = CFAbsoluteTimeGetCurrent();
    [[BugsnagPerformanceCrossTalkAPI sharedInstance] willEndUIInitSpan:state_.uiInitSpan];
    [state_.appStartSpan endWithAbsoluteTime:state_.didBecomeActiveAtTime];
    if (state_.firstViewName == nil) {
        [state_.uiInitSpan blockWithTimeout:kFirstViewDelayThreshold];
    }
    [state_.uiInitSpan endWithAbsoluteTime:state_.didBecomeActiveAtTime];
}

void
AppStartupInstrumentation::beginAppStartSpan() noexcept {
    if (!isEnabled_) {
        return;
    }
    if (state_.appStartSpan != nullptr) {
        return;
    }

    state_.appStartSpan = spanFactory_->startAppStartSpan(state_.didStartProcessAtTime,
                                                          state_.isColdLaunch,
                                                          state_.firstViewName);
}

void
AppStartupInstrumentation::beginPreMainSpan() noexcept {
    if (!isEnabled_) {
        return;
    }
    if (state_.preMainSpan != nullptr) {
        return;
    }

    state_.preMainSpan = spanFactory_->startPreMainSpan(state_.didStartProcessAtTime, state_.appStartSpan);
}

void
AppStartupInstrumentation::beginPostMainSpan() noexcept {
    if (!isEnabled_) {
        return;
    }
    if (state_.postMainSpan != nullptr) {
        return;
    }

    state_.postMainSpan = spanFactory_->startPostMainSpan(state_.didCallMainFunctionAtTime, state_.appStartSpan);
}

void
AppStartupInstrumentation::beginUIInitSpan() noexcept {
    if (!isEnabled_) {
        return;
    }
    if (state_.uiInitSpan != nullptr) {
        return;
    }
    
    BugsnagPerformanceSpanCondition *appStartCondition = [state_.appStartSpan blockWithTimeout:0.1];
    NSArray *conditionsToEndOnClose = @[];
    if (appStartCondition) {
        conditionsToEndOnClose = @[appStartCondition];
    }

    state_.uiInitSpan = spanFactory_->startUIInitSpan(state_.didFinishLaunchingAtTime, state_.appStartSpan, conditionsToEndOnClose);
}

AppStartupInstrumentationState *
AppStartupInstrumentation::instrumentationState() noexcept {
//    auto state = [AppStartupInstrumentationState new];
//    state.appStartSpan = appStartSpan_;
//    state.preMainSpan = preMainSpan_;
//    state.postMainSpan = postMainSpan_;
//    state.uiInitSpan = uiInitSpan_;
//    state.hasFirstView = firstViewName_ != nil;
//    state.isInProgress = uiInitSpan_.isValid || uiInitSpan_.isBlocked;
//    return state;
    return state_;
}

bool
AppStartupInstrumentation::isAppStartInProgress() noexcept {
    return state_.appStartSpan != nil && (state_.appStartSpan.isValid || state_.appStartSpan.isBlocked);
}
