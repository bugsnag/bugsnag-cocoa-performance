//
//  AppStartupInstrumentation.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import <Foundation/Foundation.h>
#import <mutex>
#import "../Configurable.h"
#import "../SpanAttributesProvider.h"

@class BugsnagPerformanceSpan;

namespace bugsnag {

class BugsnagPerformanceImpl;

class AppStartupInstrumentation: public Configurable {
    friend class BugsnagPerformanceLibrary;
public:
    void configure(BugsnagPerformanceConfiguration *config) noexcept;

    void didStartViewLoadSpan(NSString *name) noexcept;

private:
    std::shared_ptr<BugsnagPerformanceImpl> bugsnagPerformance_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
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
    AppStartupInstrumentation() = delete;
    AppStartupInstrumentation(std::shared_ptr<BugsnagPerformanceImpl> bugsnagPerformance,
                              std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) noexcept;

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

    void willCallMainFunction() noexcept;
    void onAppDidFinishLaunching() noexcept;
    void onAppDidBecomeActive() noexcept;
    void beginAppStartSpan() noexcept;
    void beginPreMainSpan() noexcept;
    void beginPostMainSpan() noexcept;
    void beginUIInitSpan() noexcept;
};
}
