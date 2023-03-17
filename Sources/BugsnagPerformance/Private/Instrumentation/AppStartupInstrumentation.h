//
//  AppStartupInstrumentation.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#import <Foundation/Foundation.h>

namespace bugsnag {
class AppStartupInstrumentation {
public:
    AppStartupInstrumentation(class Tracer &tracer) noexcept
    : tracer_(tracer)
    {}
    
    void start() noexcept;
    
private:
    static void initialize() noexcept __attribute__((constructor));
    
    static void notificationCallback(CFNotificationCenterRef center,
                                     void *observer,
                                     CFNotificationName name,
                                     const void *object,
                                     CFDictionaryRef userInfo) noexcept;
    
    static CFAbsoluteTime getProcessStartTime() noexcept;
    
    void reportSpan(CFAbsoluteTime endTime) noexcept;
    
    class Tracer &tracer_;
    bool isCold_{false};
};
}
