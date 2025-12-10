//
//  NSTimer+MainThread.m
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 09/12/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NSTimer+MainThread.h"

@implementation NSTimer (MainThread)

+ (NSTimer *)mainThreadTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (NS_SWIFT_SENDABLE ^)(NSTimer *timer))block {
    NSTimer *timer = [self timerWithTimeInterval:interval repeats:repeats block:block];
    if ([NSThread isMainThread]) {
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([timer isValid]) {
                [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
            }
        });
    }
    return timer;
}

@end
