//
//  BSGPerformanceSharedSessionProxy.mm
//  BugsnagPerformance-iOS
//
//  Created by Robert Bartoszewski on 24/10/2024.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BSGPerformanceSharedSessionProxy.h"
#import <objc/runtime.h>

#define FINISH_TASK_AND_INVALIDATE_SELECTOR @selector(finishTasksAndInvalidate)
#define INVALIDATE_AND_CANCEL_SELECTOR @selector(invalidateAndCancel)

@interface BSGPerformanceSharedSessionProxy ()

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation BSGPerformanceSharedSessionProxy

+ (BOOL)respondsToSelector:(SEL)aSelector {
    return [NSURLSession respondsToSelector:aSelector];
}

+ (Class)class {
    return [NSURLSession class];
}

+ (BOOL)selectorShouldBeForwarded:(SEL)aSelector {
    return !(sel_isEqual(aSelector, FINISH_TASK_AND_INVALIDATE_SELECTOR) ||
             sel_isEqual(aSelector, INVALIDATE_AND_CANCEL_SELECTOR));
}

- (id)initWithSession:(NSURLSession *)session {
    _session = session;
    return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if ([BSGPerformanceSharedSessionProxy selectorShouldBeForwarded:aSelector]) {
        return self.session;
    } else {
        return self;
    }
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    if (![BSGPerformanceSharedSessionProxy selectorShouldBeForwarded:invocation.selector]) {
        return;
    }
    [self.session forwardInvocation:invocation];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.session methodSignatureForSelector:sel];
}

@end
