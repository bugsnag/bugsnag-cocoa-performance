//
//  FrameMetricsSnapshot.mm
//  BugsnagPerformance
//
//  Created by Robert B on 23/08/2024.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FrameMetricsSnapshot.h"

@implementation FrameMetricsSnapshot

+ (FrameMetricsSnapshot *)mergeWithStart:(FrameMetricsSnapshot *)startSnapshot end:(FrameMetricsSnapshot *)endSnapshot {
    auto result = [FrameMetricsSnapshot new];
    result.totalFrames = endSnapshot.totalFrames - startSnapshot.totalFrames;
    result.totalSlowFrames = endSnapshot.totalSlowFrames - startSnapshot.totalSlowFrames;
    result.totalFrozenFrames = endSnapshot.totalFrozenFrames - startSnapshot.totalFrozenFrames;
    result.firstFrozenFrame = startSnapshot.lastFrozenFrame.next;
    result.lastFrozenFrame = endSnapshot.lastFrozenFrame;
    return result;
}

@end
