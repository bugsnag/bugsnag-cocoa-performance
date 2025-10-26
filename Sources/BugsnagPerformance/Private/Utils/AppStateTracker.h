//
//  AppStateTracker.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.03.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppStateTracker : NSObject

@property(nonatomic,readonly) BOOL isInForeground;

@property(nonatomic,readwrite,strong) void (^onTransitionToForeground)(void);
@property(nonatomic,readwrite,strong) void (^onTransitionToBackground)(void);

@property(nonatomic,readwrite,strong) void (^onAppFinishedLaunching)(void);

@end

NS_ASSUME_NONNULL_END
