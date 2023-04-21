//
//  NSURLSession+Instrumentation.m
//
//
//  Created by Karl Stenerud on 20.10.22.
//

#import "NSURLSession+Instrumentation.h"
#import "BSGURLSessionPerformanceProxy.h"
#import "../../Swizzle.h"
#import <objc/runtime.h>

using namespace bugsnag;

static void replace_NSURLSession_sessionWithConfigurationDelegateQueue(id<NSURLSessionTaskDelegate> taskDelegate) {
    Class clazz = NSURLSession.class;
    SEL selector = @selector(sessionWithConfiguration:delegate:delegateQueue:);
    typedef NSURLSession *(*IMPPrototype)(id, SEL, NSURLSessionConfiguration *,
                                          id<NSURLSessionDelegate>, NSOperationQueue *);
    __block IMPPrototype originalIMP = (IMPPrototype)ObjCSwizzle::setMethodImplementation(clazz,
                                                                   selector,
                                                                   ^(id self,
                                                                     NSURLSessionConfiguration *configuration,
                                                                     id<NSURLSessionDelegate> sessionDelegate,
                                                                     NSOperationQueue *queue) {
        if (sessionDelegate) {
            sessionDelegate = [[BSGURLSessionPerformanceProxy alloc] initWithSessionDelegate:sessionDelegate taskDelegate:taskDelegate];
        } else {
            sessionDelegate = taskDelegate;
        }
        return originalIMP(self, selector, configuration, sessionDelegate, queue);
    });
}

static void replace_NSURLSession_sharedSession() {
    ObjCSwizzle::setMethodImplementation(NSURLSession.class, @selector(sharedSession), ^(__unused id self) {
        static NSURLSession *session;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            // The shared session uses the shared NSURLCache, NSHTTPCookieStorage,
            // and NSURLCredentialStorage objects, uses a shared custom networking
            // protocol list (configured with registerClass: and unregisterClass:),
            // and is based on a default configuration.
            // https://developer.apple.com/documentation/foundation/nsurlsession/1409000-sharedsession
            session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                    delegate:nil delegateQueue:nil];
        });

        return session;
    });
}

void bsg_installNSURLSessionPerformance(id<NSURLSessionTaskDelegate> taskDelegate) {
    replace_NSURLSession_sessionWithConfigurationDelegateQueue(taskDelegate);
    replace_NSURLSession_sharedSession();
}
