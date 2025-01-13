//
//  BugsnagSwiftTools.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 12.11.24.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import "BugsnagSwiftTools.h"
#import <BugsnagPerformance/BugsnagPerformanceTrackedViewContainer.h>

@implementation BugsnagSwiftTools

// Selector used by BugsnagSwiftToolsImpl
+ (NSString * _Nonnull)demangledClassNameFromInstanceWithObject:(id _Nonnull)object {
    return [self demangledClassNameFromInstance:object];
}

+ (NSString * _Nonnull)demangledClassNameFromInstance:(id _Nonnull)object {
    // BugsnagSwiftToolsImpl is part of the optional BugsnagPerformanceSwift, and may not be linked in
    static Class impl = nil;
    static bool implExists = false;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        impl = NSClassFromString(@"BugsnagPerformanceSwift.BugsnagSwiftToolsImpl");
        implExists = [impl respondsToSelector:@selector(demangledClassNameFromInstanceWithObject:)];
    });
    if (implExists) {
        return [impl demangledClassNameFromInstanceWithObject:object];
    }

    // Fallback if BugsnagSwiftToolsImpl is not available

    if ([object respondsToSelector:@selector(bugsnagPerformanceTrackedViewName)]) {
        return [(id)object bugsnagPerformanceTrackedViewName];
    }

    return NSStringFromClass([object class]);
}

@end
