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
    if (!isRunningInAppExtension()) {
        return [GetUIApplication() applicationState] != UIApplicationStateBackground;
    }
#endif
    return YES;
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
