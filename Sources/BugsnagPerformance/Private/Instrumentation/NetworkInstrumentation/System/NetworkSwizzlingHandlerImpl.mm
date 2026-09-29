//
//  NetworkSwizzlingHandlerImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 01/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NetworkSwizzlingHandlerImpl.h"
#import "Proxy/BSGURLSessionPerformanceProxy.h"
#import "Proxy/BSGPerformanceSharedSessionProxy.h"
#import "../../../Swizzle.h"
#import <objc/runtime.h>
#import "../../../Logging.h"

using namespace bugsnag;

static const void *kGraphQLResponseBodyKey = &kGraphQLResponseBodyKey;
static const NSUInteger kMaxCapturedGraphQLResponseBodyBytes = 64 * 1024;

extern "C" void BSGAssociateGraphQLResponseBodyWithTask(NSURLSessionTask *task, NSData *body) {
    if (task == nil || body.length == 0 || body.length > kMaxCapturedGraphQLResponseBodyBytes) {
        return;
    }
    objc_setAssociatedObject(task, kGraphQLResponseBodyKey, body, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

extern "C" NSData *BSGCapturedGraphQLResponseBodyForTask(NSURLSessionTask *task) {
    return task == nil ? nil : objc_getAssociatedObject(task, kGraphQLResponseBodyKey);
}

extern "C" void BSGClearCapturedGraphQLResponseBodyForTask(NSURLSessionTask *task) {
    if (task != nil) {
        objc_setAssociatedObject(task, kGraphQLResponseBodyKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

void
NetworkSwizzlingHandlerImpl::instrumentSession(id<NSURLSessionTaskDelegate> taskDelegate,
                                               BSGIsEnabledCallback isEnabled) noexcept {
    instrumentSessionWithConfigurationDelegateQueue(taskDelegate, isEnabled);
    instrumentSharedSession(isEnabled);
    instrumentSessionCompletionHandlers(isEnabled);
}

void
NetworkSwizzlingHandlerImpl::instrumentTask(Class cls, BSGSessionTaskResumeCallback onResume) noexcept {
    __weak BSGSessionTaskResumeCallback weakOnResume = onResume;
    __block SEL selector = @selector(resume);
    __block IMP resume = ObjCSwizzle::replaceInstanceMethodOverride(cls, selector, ^(id self) {
        BSGSessionTaskResumeCallback localOnResume = weakOnResume;
        if (localOnResume != nil) {
            localOnResume(self);
        }
        if (resume) {
            reinterpret_cast<void (*)(id, SEL)>(resume)(self, selector);
        }
    });
}

#pragma mark Helpers

void
NetworkSwizzlingHandlerImpl::instrumentSharedSession(BSGIsEnabledCallback isEnabled) noexcept {
    __weak BSGIsEnabledCallback weakIsEnbled = isEnabled;
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

void
NetworkSwizzlingHandlerImpl::instrumentSessionWithConfigurationDelegateQueue(id<NSURLSessionTaskDelegate> taskDelegate,
                                                                             BSGIsEnabledCallback isEnabled) noexcept {
    __weak BSGIsEnabledCallback weakIsEnbled = isEnabled;
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

void
NetworkSwizzlingHandlerImpl::instrumentSessionCompletionHandlers(BSGIsEnabledCallback isEnabled) noexcept {
    __weak BSGIsEnabledCallback weakIsEnabled = isEnabled;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        {
            SEL selector = @selector(dataTaskWithRequest:completionHandler:);
            typedef NSURLSessionDataTask *(*IMPPrototype)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *));
            __block IMPPrototype originalIMP = (IMPPrototype)ObjCSwizzle::replaceInstanceMethodOverride(NSURLSession.class, selector,
                ^NSURLSessionDataTask *(NSURLSession *session, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
                    BSGIsEnabledCallback localIsEnabled = weakIsEnabled;
                    if (localIsEnabled != nil && !localIsEnabled()) {
                        return originalIMP(session, selector, request, completionHandler);
                    }
                    __block NSURLSessionDataTask *task = nil;
                    void (^wrappedCompletion)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
                        BSGAssociateGraphQLResponseBodyWithTask(task, data);
                        if (completionHandler != nil) {
                            completionHandler(data, response, error);
                        }
                    };
                    task = originalIMP(session, selector, request, wrappedCompletion);
                    return task;
                });
        }
        {
            SEL selector = @selector(dataTaskWithURL:completionHandler:);
            typedef NSURLSessionDataTask *(*IMPPrototype)(id, SEL, NSURL *, void (^)(NSData *, NSURLResponse *, NSError *));
            __block IMPPrototype originalIMP = (IMPPrototype)ObjCSwizzle::replaceInstanceMethodOverride(NSURLSession.class, selector,
                ^NSURLSessionDataTask *(NSURLSession *session, NSURL *url, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
                    BSGIsEnabledCallback localIsEnabled = weakIsEnabled;
                    if (localIsEnabled != nil && !localIsEnabled()) {
                        return originalIMP(session, selector, url, completionHandler);
                    }
                    __block NSURLSessionDataTask *task = nil;
                    void (^wrappedCompletion)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
                        BSGAssociateGraphQLResponseBodyWithTask(task, data);
                        if (completionHandler != nil) {
                            completionHandler(data, response, error);
                        }
                    };
                    task = originalIMP(session, selector, url, wrappedCompletion);
                    return task;
                });
        }
        {
            SEL selector = @selector(uploadTaskWithRequest:fromData:completionHandler:);
            typedef NSURLSessionUploadTask *(*IMPPrototype)(id, SEL, NSURLRequest *, NSData *, void (^)(NSData *, NSURLResponse *, NSError *));
            __block IMPPrototype originalIMP = (IMPPrototype)ObjCSwizzle::replaceInstanceMethodOverride(NSURLSession.class, selector,
                ^NSURLSessionUploadTask *(NSURLSession *session, NSURLRequest *request, NSData *bodyData, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
                    BSGIsEnabledCallback localIsEnabled = weakIsEnabled;
                    if (localIsEnabled != nil && !localIsEnabled()) {
                        return originalIMP(session, selector, request, bodyData, completionHandler);
                    }
                    __block NSURLSessionUploadTask *task = nil;
                    void (^wrappedCompletion)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
                        BSGAssociateGraphQLResponseBodyWithTask(task, data);
                        if (completionHandler != nil) {
                            completionHandler(data, response, error);
                        }
                    };
                    task = originalIMP(session, selector, request, bodyData, wrappedCompletion);
                    return task;
                });
        }
    });
}
