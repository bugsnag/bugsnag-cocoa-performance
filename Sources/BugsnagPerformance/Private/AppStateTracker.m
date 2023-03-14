//
//  AppStateTracker.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.03.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "AppStateTracker.h"

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#endif
#if __has_include(<AppKit/AppKit.h>)
#import <AppKit/AppKit.h>
#endif
#if __has_include(<WatchKit/WatchKit.h>)
#import <WatchKit/WatchKit.h>
#endif

@implementation AppStateTracker

- (instancetype) init {
    if ((self = [super init])) {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

#if __has_include(<AppKit/AppKit.h>)
        [notificationCenter addObserver:self
                               selector:@selector(handleAppForegroundEvent)
                                   name:NSApplicationDidBecomeActiveNotification
                                 object:nil];
#endif

#if __has_include(<UIKit/UIKit.h>)
        [notificationCenter addObserver:self
                               selector:@selector(handleAppForegroundEvent)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];
#endif

#if __has_include(<WatchKit/WatchKit.h>)
        [notificationCenter addObserver:self
                               selector:@selector(handleAppForegroundEvent)
                                   name:WKApplicationDidBecomeActiveNotification
                                 object:nil];
#endif
    }
    return self;
}

- (void) handleAppForegroundEvent {
    void (^callback)(void) = self.onTransitionToForeground;
    if (callback != nil) {
        callback();
    }
}

@end
