//
//  AppStartupInstrumentation.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import <Foundation/Foundation.h>
#import <mutex>
#import "../Configurable.h"
#import "../Startable.h"
#import "../SpanAttributesProvider.h"
#import "../Tracer.h"

@class BugsnagPerformanceSpan;

namespace bugsnag {

class BugsnagPerformanceImpl;

class AppStartupInstrumentation: public Configurable, public Startable {
public:
    AppStartupInstrumentation(std::shared_ptr<Tracer> tracer,
                              std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) noexcept;
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void start() noexcept;

    void didStartViewLoadSpan(NSString *name) noexcept;
    void willCallMainFunction() noexcept;

private:
    bool isEnabled_{true}; // AppStartupInstrumentation starts out enabled
    std::shared_ptr<Tracer> tracer_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
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
};
}
