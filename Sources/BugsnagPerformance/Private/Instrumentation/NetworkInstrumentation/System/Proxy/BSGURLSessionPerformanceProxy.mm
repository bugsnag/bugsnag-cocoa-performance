//
//  BSGURLSessionPerformanceProxy.m
//
//
//  Created by Karl Stenerud on 20.10.22.
//

#import "BSGURLSessionPerformanceProxy.h"
#import <objc/runtime.h>
#import "../../../../Utils/Utils.h"

@interface BSGURLSessionPerformanceProxy ()

@property (nonatomic, strong, readonly, nonnull) id<NSURLSessionDelegate> sessionDelegate;
@property (nonatomic, strong, readonly, nonnull) id<NSURLSessionTaskDelegate> taskDelegate;

@end


@implementation BSGURLSessionPerformanceProxy

#define METRICS_SELECTOR @selector(URLSession:task:didFinishCollectingMetrics:)

- (instancetype)initWithSessionDelegate:(nonnull id<NSURLSessionDelegate>)sessionDelegate
                           taskDelegate:(nonnull id<NSURLSessionTaskDelegate>) taskDelegate {
    _sessionDelegate = sessionDelegate;
    _taskDelegate = taskDelegate;

    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [self.sessionDelegate respondsToSelector:aSelector];
}

// Implementing this method prevents a crash when used alongside NewRelic
- (id)forwardingTargetForSelector:(__unused SEL)aSelector {
    return self.sessionDelegate;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.sessionDelegate];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if (sel_isEqual(aSelector, METRICS_SELECTOR)) {
        return [(NSObject *)self.taskDelegate methodSignatureForSelector:aSelector];
    }
    return [(NSObject *)self.sessionDelegate methodSignatureForSelector:aSelector];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics
API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {
    BSGLogTrace("BSGURLSessionPerformanceProxy:URLSession:%@ task:%@ didFinishCollectingMetrics", session.class, task.class);
    [self.taskDelegate URLSession:session task:task didFinishCollectingMetrics:metrics];

    if ([self.sessionDelegate respondsToSelector:METRICS_SELECTOR]) {
        [(id)self.sessionDelegate URLSession:session task:task didFinishCollectingMetrics:metrics];
    }
}

@end
