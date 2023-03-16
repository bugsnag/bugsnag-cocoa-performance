//
//  AppStateTracker.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.03.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppStateTracker : NSObject

- (instancetype)init __attribute__((unavailable("use sharedInstance"))) NS_UNAVAILABLE;

+ (instancetype)sharedInstance;

@property(nonatomic,readonly) BOOL isInForeground;

@property(nonatomic,readwrite,strong) void (^onTransitionToForeground)(void);

@end

NS_ASSUME_NONNULL_END
