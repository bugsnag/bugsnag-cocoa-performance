//
//  AppStartupInstrumentation.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import <Foundation/Foundation.h>
#import <mutex>
#import "../../PhasedStartup.h"
#import "../../SpanAttributesProvider.h"
#import "../../Tracer.h"
#import "State/AppStartupInstrumentationState.h"
#import "SpanFactory/AppStartupSpanFactory.h"
#import "System/AppStartupInstrumentationSystemUtils.h"

@class BugsnagPerformanceSpan;

namespace bugsnag {

class BugsnagPerformanceImpl;

class AppStartupInstrumentation: public PhasedStartup {
public:
    AppStartupInstrumentation(std::shared_ptr<AppStartupSpanFactory> spanFactory,
                              std::shared_ptr<AppStartupInstrumentationSystemUtils> systemUtils) noexcept;

    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept;
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept {}
    void start() noexcept {}

    void didStartViewLoadSpan(NSString *name) noexcept;
    void willCallMainFunction() noexcept;
    void abortAllSpans() noexcept;

    /**
     * Returns the time from when the earliest BugsnagPerformance code ran (__attribute__((constructor(101))))
     * until we received UIApplicationDidFinishLaunchingNotification (or the current time, if that hasn't happened yet).
     */
    CFAbsoluteTime appStartDuration() noexcept;

    CFAbsoluteTime timeSinceAppFirstBecameActive() noexcept;

private:
    bool isEnabled_{true};
    std::shared_ptr<AppStartupSpanFactory> spanFactory_;
    std::shared_ptr<AppStartupInstrumentationSystemUtils> systemUtils_;
    CFAbsoluteTime didStartProcessAtTime_{0};
    CFAbsoluteTime didCallMainFunctionAtTime_{0};
    CFAbsoluteTime didBecomeActiveAtTime_{0};
    CFAbsoluteTime didFinishLaunchingAtTime_{0};
    bool isColdLaunch_{false};
    bool shouldRespondToAppDidFinishLaunching_{false};
    bool shouldRespondToAppDidBecomeActive_{false};
    BugsnagPerformanceSpan *appStartSpan_{nil};
    BugsnagPerformanceSpan *preMainSpan_{nil};
    BugsnagPerformanceSpan *postMainSpan_{nil};
    BugsnagPerformanceSpan *uiInitSpan_{nil};
    NSString *firstViewName_{nil};
    std::mutex mutex_;

private:
    AppStartupInstrumentation() = delete;

    // Disable app startup instrumentation and cancel any already-created spans.
    void disable() noexcept;

    static void didFinishLaunchingCallback(CFNotificationCenterRef center,
                                           void *observer,
                                           CFNotificationName name,
                                           const void *object,
                                           CFDictionaryRef userInfo) noexcept;

    static void didBecomeActiveCallback(CFNotificationCenterRef center,
                                        void *observer,
                                        CFNotificationName name,
                                        const void *object,
                                        CFDictionaryRef userInfo) noexcept;

    void onAppDidFinishLaunching() noexcept;
    void onAppDidBecomeActive() noexcept;
    void beginAppStartSpan() noexcept;
    void beginPreMainSpan() noexcept;
    void beginPostMainSpan() noexcept;
    void beginUIInitSpan() noexcept;
    AppStartupInstrumentationState *instrumentationState() noexcept;
    bool isAppStartInProgress() noexcept;
};
}
