//
//  FrameMetricsSnapshot.h
//  BugsnagPerformance
//
//  Created by Robert B on 23/08/2024.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#pragma once
#import "../PhasedStartup.h"
#import "FrozenFrameData.h"

@interface FrameMetricsSnapshot: NSObject

@property(nonatomic, readwrite) uint64_t totalFrames;
@property(nonatomic, readwrite) uint64_t totalSlowFrames;
@property(nonatomic, readwrite) uint64_t totalFrozenFrames;

@property(nonatomic, strong) FrozenFrameData *firstFrozenFrame;
@property(nonatomic, strong) FrozenFrameData *lastFrozenFrame;

+ (FrameMetricsSnapshot *)mergeWithStart:(FrameMetricsSnapshot *)startSnapshot end:(FrameMetricsSnapshot *)endSnapshot;

@end

