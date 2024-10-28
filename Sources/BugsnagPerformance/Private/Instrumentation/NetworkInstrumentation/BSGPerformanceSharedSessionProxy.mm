//
//  BSGPerformanceSharedSessionProxy.mm
//  BugsnagPerformance-iOS
//
//  Created by Robert B on 24/10/2024.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BSGPerformanceSharedSessionProxy.h"
#import <objc/runtime.h>

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
    NSString *selectorString = NSStringFromSelector(aSelector);
    return !([selectorString isEqual:@"finishTasksAndInvalidate"] || [selectorString isEqual:@"invalidateAndCancel"]);
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
