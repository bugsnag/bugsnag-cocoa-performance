//
//  AppStartupInstrumentationStateSnapshot.m
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "AppStartupInstrumentationStateSnapshot.h"

@interface AppStartupInstrumentationStateSnapshot ()
@property (nonatomic, strong) BugsnagPerformanceSpan *appStartSpan;
@property (nonatomic, strong) BugsnagPerformanceSpan *uiInitSpan;
@property (nonatomic) BOOL isInProgress;
@property (nonatomic) BOOL hasFirstView;
@property (nonatomic) BOOL shouldIncludeFirstViewLoad;
@end

@implementation AppStartupInstrumentationStateSnapshot

+ (instancetype)snapshotWithAppStartSpan:(BugsnagPerformanceSpan *)appStartSpan
                              uiInitSpan:(BugsnagPerformanceSpan *)uiInitSpan
                            isInProgress:(BOOL)isInProgress
                            hasFirstView:(BOOL)hasFirstView
              shouldIncludeFirstViewLoad:(BOOL)shouldIncludeFirstViewLoad {
    AppStartupInstrumentationStateSnapshot *snapshot = [self new];
    snapshot.appStartSpan = appStartSpan;
    snapshot.uiInitSpan = uiInitSpan;
    snapshot.isInProgress = isInProgress;
    snapshot.hasFirstView = hasFirstView;
    snapshot.shouldIncludeFirstViewLoad = shouldIncludeFirstViewLoad;
    return snapshot;
}

@end
