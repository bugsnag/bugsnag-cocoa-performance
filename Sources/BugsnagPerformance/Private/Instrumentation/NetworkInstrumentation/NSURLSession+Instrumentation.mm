//
//  NSURLSession+Instrumentation.m
//
//
//  Created by Karl Stenerud on 20.10.22.
//

#import "NSURLSession+Instrumentation.h"
#import "System/Proxy/BSGURLSessionPerformanceProxy.h"
#import "../../Swizzle.h"
#import "System/Proxy/BSGPerformanceSharedSessionProxy.h"
#import <objc/runtime.h>

using namespace bugsnag;

static void replace_NSURLSession_sessionWithConfigurationDelegateQueue(id<NSURLSessionTaskDelegate> taskDelegate, BSGIsEnabledCallback isEnbled) {
    __weak BSGIsEnabledCallback weakIsEnbled = isEnbled;
    Class clazz = NSURLSession.class;
    SEL selector = @selector(sessionWithConfiguration:delegate:delegateQueue:);
    typedef NSURLSession *(*IMPPrototype)(id, SEL, NSURLSessionConfiguration *,
                                          id<NSURLSessionDelegate>, NSOperationQueue *);
    __block IMPPrototype originalIMP = (IMPPrototype)ObjCSwizzle::setClassMethodImplementation(clazz,
                                                                   selector,
                                                                   ^(id self,
                                                                     NSURLSessionConfiguration *configuration,
                                                                     id<NSURLSessionDelegate> sessionDelegate,
                                                                     NSOperationQueue *queue) {
        BSGIsEnabledCallback localIsEnabled = weakIsEnbled;
        if (localIsEnabled != nil && !localIsEnabled()) {
            return originalIMP(self, selector, configuration, sessionDelegate, queue);
        }

        if (sessionDelegate) {
            sessionDelegate = [[BSGURLSessionPerformanceProxy alloc] initWithSessionDelegate:sessionDelegate taskDelegate:taskDelegate];
        } else {
            sessionDelegate = taskDelegate;
        }
        return originalIMP(self, selector, configuration, sessionDelegate, queue);
    });
}

static void replace_NSURLSession_sharedSession(BSGIsEnabledCallback isEnbled) {
    __weak BSGIsEnabledCallback weakIsEnbled = isEnbled;
    typedef NSURLSession *(*IMPPrototype)(id, SEL);
    SEL selector = @selector(sharedSession);
    __block IMPPrototype originalIMP = (IMPPrototype)ObjCSwizzle::setClassMethodImplementation(NSURLSession.class, selector, ^(__unused id self) {
        BSGIsEnabledCallback localIsEnabled = weakIsEnbled;
        if (localIsEnabled != nil && !localIsEnabled()) {
            return originalIMP(self, selector);
        }

        static BSGPerformanceSharedSessionProxy *sessionProxy;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            // The shared session uses the shared NSURLCache, NSHTTPCookieStorage,
            // and NSURLCredentialStorage objects, uses a shared custom networking
            // protocol list (configured with registerClass: and unregisterClass:),
            // and is based on a default configuration.
            // https://developer.apple.com/documentation/foundation/nsurlsession/1409000-sharedsession

            NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:nil];
            sessionProxy = [[BSGPerformanceSharedSessionProxy alloc] initWithSession:session];
        });

        return (NSURLSession *)sessionProxy;
    });
}


void bsg_installNSURLSessionPerformance(id<NSURLSessionTaskDelegate> taskDelegate, BSGIsEnabledCallback isEnabled) {
    replace_NSURLSession_sessionWithConfigurationDelegateQueue(taskDelegate, isEnabled);
    replace_NSURLSession_sharedSession(isEnabled);
}
