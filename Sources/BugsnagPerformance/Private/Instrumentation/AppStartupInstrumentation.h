//
//  AppStartupInstrumentation.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import <Foundation/Foundation.h>
#import <mutex>

@class BugsnagPerformanceSpan;

namespace bugsnag {

class BugsnagPerformanceImpl;

class AppStartupInstrumentation {
public:
    static std::shared_ptr<AppStartupInstrumentation> sharedInstance();

    // Disable app startup instrumentation and cancel any already-created spans.
    void disable() noexcept;

    void didStartViewLoadSpan(NSString *name) noexcept;

private:
    BugsnagPerformanceImpl &bugsnagPerformance_;
    CFAbsoluteTime didStartProcessAtTime_{0};
    CFAbsoluteTime didCallMainFunctionAtTime_{0};
    CFAbsoluteTime didBecomeActiveAtTime_{0};
    CFAbsoluteTime didFinishLaunchingAtTime_{0};
    bool isDisabled_{false};
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
    AppStartupInstrumentation();
    static std::shared_ptr<AppStartupInstrumentation> create()
    {
        std::shared_ptr<AppStartupInstrumentation> pA(new AppStartupInstrumentation());
        return pA;
    }

    // Use the constructor attribute so that this runs right before main()
    // https://gcc.gnu.org/onlinedocs/gcc-4.7.0/gcc/Function-Attributes.html
    // Priority is 101-65535, with higher values running later.
    static void initialize() noexcept __attribute__((constructor(65535)));

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

    void start() noexcept;
    void onAppDidFinishLaunching() noexcept;
    void onAppDidBecomeActive() noexcept;
    void beginAppStartSpan() noexcept;
    void beginPreMainSpan() noexcept;
    void beginPostMainSpan() noexcept;
    void beginUIInitSpan() noexcept;
};
}
