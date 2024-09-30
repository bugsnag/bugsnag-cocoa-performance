//
//  FrozenFrameData.h
//  BugsnagPerformance
//
//  Created by Robert B on 05/09/2024.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#pragma once
#import "../PhasedStartup.h"

@interface FrozenFrameData: NSObject

@property(nonatomic, readonly) NSTimeInterval startTime;
@property(nonatomic, readonly) NSTimeInterval endTime;
@property(nonatomic, strong) FrozenFrameData *next;

- (instancetype)initWithStartTime:(NSTimeInterval)startTime endTime:(NSTimeInterval)endTime;

+ (FrozenFrameData *)root;

@end
