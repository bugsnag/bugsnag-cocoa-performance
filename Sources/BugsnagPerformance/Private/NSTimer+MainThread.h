//
//  NSTimer+MainThread.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 09/12/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTimer (MainThread)

/// Creates and returns a new NSTimer object initialized with the specified block object and schedules it on the main run loop in the default mode.
/// - parameter:  ti    The number of seconds between firings of the timer. If seconds is less than or equal to 0.0, this method chooses the nonnegative value of 0.1 milliseconds instead
/// - parameter:  repeats  If YES, the timer will repeatedly reschedule itself until invalidated. If NO, the timer will be invalidated after it fires.
/// - parameter:  block  The execution body of the timer; the timer itself is passed as the parameter to this block when executed to aid in avoiding cyclical references
+ (NSTimer *)mainThreadTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (NS_SWIFT_SENDABLE ^)(NSTimer *timer))block API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));

@end
