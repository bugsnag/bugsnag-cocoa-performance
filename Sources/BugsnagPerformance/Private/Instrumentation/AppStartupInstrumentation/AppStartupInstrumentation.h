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
#import "State/AppStartupInstrumentationStateSnapshot.h"
#import "Lifecycle/AppStartupLifecycleHandler.h"
#import "System/AppStartupInstrumentationSystemUtils.h"

@class BugsnagPerformanceSpan;

namespace bugsnag {

class BugsnagPerformanceImpl;

class AppStartupInstrumentation: public PhasedStartup {
public:
    AppStartupInstrumentation(std::shared_ptr<AppStartupLifecycleHandler> lifecycleHandler,
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
    
    AppStartupInstrumentationStateSnapshot *stateSnapshot() noexcept;

private:
    bool isEnabled_{true};
    std::shared_ptr<AppStartupLifecycleHandler> lifecycleHandler_;
    std::shared_ptr<AppStartupInstrumentationSystemUtils> systemUtils_;
    AppStartupInstrumentationState *state_;
    std::mutex mutex_;
    
    void onAppDidFinishLaunching() noexcept;
    void onAppDidBecomeActive() noexcept;
    
    void startObservingNotifications() noexcept;
    void stopObservingNotifications() noexcept;

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
    
    AppStartupInstrumentation() = delete;
};
}
