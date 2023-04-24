//
//  AppStateTracker.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.03.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "AppStateTracker.h"
#import "Targets.h"

#import <sys/sysctl.h>
#import <mach/mach.h>

#if __has_include(<os/proc.h>)
#include <os/proc.h>
#endif

#if BSG_TARGET_UIKIT
#import <UIKit/UIKit.h>
#define UIAPPLICATION NSClassFromString(@"UIApplication")
#endif

#if BSG_TARGET_APPKIT
#import <AppKit/AppKit.h>
#endif

#if BSG_TARGET_WATCHKIT
#import <WatchKit/WatchKit.h>
#endif

static BOOL isRunningInAppExtension(void) {
    // From "Information Property List Key Reference" > "App Extension Keys"
    // https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/AppExtensionKeys.html
    //
    // NSExtensionPointIdentifier
    // String - iOS, macOS. Specifies the extension point that supports an app extension, in reverse-DNS notation.
    // This key is required for every app extension, and must be placed as an immediate child of the NSExtension key.
    // Each Xcode app extension template is preconfigured with the appropriate extension point identifier key.
    return NSBundle.mainBundle.infoDictionary[@"NSExtension"][@"NSExtensionPointIdentifier"] != nil;
}

#if TARGET_OS_IOS || TARGET_OS_TV

static UIApplication * GetUIApplication(void) {
    // +sharedApplication is unavailable to app extensions
    if (isRunningInAppExtension()) {
        return nil;
    }
    if (![UIAPPLICATION respondsToSelector:@selector(sharedApplication)]) {
        return nil;
    }
    // Using performSelector: to avoid a compile-time check that
    // +sharedApplication is not called from app extensions
    return [UIAPPLICATION performSelector:@selector(sharedApplication)];
}

#endif

static bool GetIsForeground(void) {
#if TARGET_OS_OSX
    return [[NSAPPLICATION sharedApplication] isActive];
#endif

#if TARGET_OS_IOS
    //
    // Work around unreliability of -[UIApplication applicationState] which
    // always returns UIApplicationStateBackground during the launch of UIScene
    // based apps (until the first scene has been created.)
    //
    task_category_policy_data_t policy;
    mach_msg_type_number_t count = TASK_CATEGORY_POLICY_COUNT;
    boolean_t get_default = FALSE;
    // task_policy_get() is prohibited on tvOS and watchOS
    kern_return_t kr = task_policy_get(mach_task_self(), TASK_CATEGORY_POLICY,
                                       (void *)&policy, &count, &get_default);
    if (kr == KERN_SUCCESS) {
        // TASK_FOREGROUND_APPLICATION  -> normal foreground launch
        // TASK_NONUI_APPLICATION       -> background launch
        // TASK_DARWINBG_APPLICATION    -> iOS 15 prewarming launch
        // TASK_UNSPECIFIED             -> iOS 9 Simulator
        if (!get_default && policy.role == TASK_FOREGROUND_APPLICATION) {
            return true;
        }
    } else {
        NSLog(@"task_policy_get failed: %s", mach_error_string(kr));
    }
#endif

#if TARGET_OS_IOS || TARGET_OS_TV
    UIApplication *application = GetUIApplication();

    // There will be no UIApplication if UIApplicationMain() has not yet been
    // called - e.g. from a SwiftUI app's init() function or UIKit app's main()
    if (!application) {
        return false;
    }

    __block UIApplicationState applicationState;
    if ([[NSThread currentThread] isMainThread]) {
        applicationState = [application applicationState];
    } else {
        // -[UIApplication applicationState] is a main thread-only API
        dispatch_sync(dispatch_get_main_queue(), ^{
            applicationState = [application applicationState];
        });
    }

    return applicationState != UIApplicationStateBackground;
#endif

#if TARGET_OS_WATCH
    WKExtension *ext = [WKExtension sharedExtension];
    return ext && ext.applicationState != WKApplicationStateBackground;
#endif
}

@implementation AppStateTracker

- (instancetype) init {
    if ((self = [super init])) {
        if ([NSThread isMainThread]) {
            _isInForeground = GetIsForeground();
        } else {
            __block AppStateTracker *blockSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                blockSelf->_isInForeground = GetIsForeground();
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

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
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
