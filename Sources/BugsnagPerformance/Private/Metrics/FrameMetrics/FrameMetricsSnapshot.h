//
//  FrameMetricsSnapshot.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/08/2024.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#pragma once
#import "../../Core/PhasedStartup.h"
#import "FrozenFrameData.h"


@interface FrameMetricsSnapshot: NSObject

@property(nonatomic, readwrite) uint64_t totalFrames;
@property(nonatomic, readwrite) uint64_t totalSlowFrames;
@property(nonatomic, readwrite) uint64_t totalFrozenFrames;

@property(nonatomic, strong) FrozenFrameData *firstFrozenFrame;
@property(nonatomic, strong) FrozenFrameData *lastFrozenFrame;

+ (FrameMetricsSnapshot *)mergeWithStart:(FrameMetricsSnapshot *)startSnapshot end:(FrameMetricsSnapshot *)endSnapshot;

@end

typedef FrameMetricsSnapshot *(^GetCurrentFrameMetricsSnapshot)();

