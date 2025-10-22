//
//  AppStartupInstrumentationStateSnapshot.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

@interface AppStartupInstrumentationStateSnapshot: NSObject
@property (nonatomic, readonly) BugsnagPerformanceSpan *appStartSpan;
@property (nonatomic, readonly) BugsnagPerformanceSpan *uiInitSpan;
@property (nonatomic, readonly) BOOL isInProgress;
@property (nonatomic, readonly) BOOL hasFirstView;

+ (instancetype)snapshotWithAppStartSpan:(BugsnagPerformanceSpan *)appStartSpan
                              uiInitSpan:(BugsnagPerformanceSpan *)uiInitSpan
                            isInProgress:(BOOL)isInProgress
                            hasFirstView:(BOOL)hasFirstView;

@end

typedef AppStartupInstrumentationStateSnapshot *(^GetAppStartupStateSnapshot)(void);
