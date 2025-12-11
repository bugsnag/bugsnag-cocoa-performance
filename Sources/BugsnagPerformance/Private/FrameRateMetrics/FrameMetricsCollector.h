//
//  FrameMetricsCollector.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/08/2024.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#pragma once
#import "../BSGPhasedStartup.h"
#import "FrameMetricsSnapshot.h"

@interface FrameMetricsCollector: NSObject<BSGPhasedStartup>

- (void)onAppEnteredBackground;
- (void)onAppEnteredForeground;
- (FrameMetricsSnapshot *)currentSnapshot;

@end

