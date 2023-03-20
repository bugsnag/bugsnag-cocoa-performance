//
//  AppStateTracker.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.03.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "AppStateTracker.h"
#import "Targets.h"

#if BSG_TARGET_UIKIT
#import <UIKit/UIKit.h>
#endif
#if BSG_TARGET_APPKIT
#import <AppKit/AppKit.h>
#endif
#if BSG_TARGET_WATCHKIT
#import <WatchKit/WatchKit.h>
#endif

@implementation AppStateTracker

+ (void)initialize {
    [self sharedInstance];
}

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

static BOOL isInForeground(void) {
#if BSG_TARGET_WATCHKIT
    return WKApplication.sharedApplication.applicationState != WKApplicationStateBackground;
#elif BSG_TARGET_UIKIT
    return UIApplication.sharedApplication.applicationState != UIApplicationStateBackground;
#else
    return YES;
#endif
}

- (instancetype) init {
    if ((self = [super init])) {
        if ([NSThread isMainThread]) {
            _isInForeground = isInForeground();
        } else {
            __block AppStateTracker *blockSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                blockSelf->_isInForeground = isInForeground();
            });
        }

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

#if BSG_TARGET_APPKIT
        [notificationCenter addObserver:self
                               selector:@selector(handleAppForegroundEvent)
                                   name:NSApplicationDidBecomeActiveNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(handleAppBackgroundEvent)
                                   name:NSApplicationDidResignActiveNotification
                                 object:nil];
#endif

#if BSG_TARGET_UIKIT
        [notificationCenter addObserver:self
                               selector:@selector(handleAppForegroundEvent)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(handleAppBackgroundEvent)
                                   name:UIApplicationDidEnterBackgroundNotification
                                 object:nil];
#endif

#if BSG_TARGET_WATCHKIT
        [notificationCenter addObserver:self
                               selector:@selector(handleAppForegroundEvent)
                                   name:WKApplicationDidBecomeActiveNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(handleAppBackgroundEvent)
                                   name:WKApplicationDidEnterBackgroundNotification
                                 object:nil];
#endif
    }
    return self;
}

- (void) handleAppForegroundEvent {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    _isInForeground = YES;
    void (^callback)(void) = self.onTransitionToForeground;
    if (callback != nil) {
        callback();
    }
}

- (void) handleAppBackgroundEvent {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    _isInForeground = NO;
}

@end
