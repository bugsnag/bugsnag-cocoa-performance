//
//  FrameMetricsCollector.mm
//  BugsnagPerformance
//
//  Created by Robert B on 23/08/2024.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "BugsnagPerformance/BugsnagPerformanceConfiguration.h"
#import "../EarlyConfiguration.h"
#import "FrameMetricsCollector.h"
#import "FrozenFrameData.h"

static const CGFloat kFrozenFrameThreshold = 0.7;
static const CGFloat kSlowFrameRatioThreshold = 1.3;

@interface FrameMetricsCollector ()

@property(nonatomic, readwrite) uint64_t totalFrames;
@property(nonatomic, readwrite) uint64_t totalSlowFrames;
@property(nonatomic, readwrite) uint64_t totalFrozenFrames;

@property(nonatomic) NSTimeInterval lastFrameTimestamp;
@property(nonatomic) NSTimeInterval nextFrameTargetTimestamp;
@property(nonatomic) NSTimeInterval frameTimestampAdjustment;

@property(nonatomic, readwrite) Boolean isInForeground;
@property(nonatomic, readwrite) Boolean justEnteredForeground;
@property(nonatomic, readwrite) Boolean autoInstrumentRendering;
@property(nonatomic, strong) FrozenFrameData *lastFrozenFrame;

@end

@implementation FrameMetricsCollector

- (instancetype)init
{
    self = [super init];
    if (self) {
        _totalFrames = 0;
        _totalSlowFrames = 0;
        _totalFrozenFrames = 0;
        _isInForeground = true;
        _justEnteredForeground = true;
        _lastFrozenFrame = [FrozenFrameData root];
        _frameTimestampAdjustment = [NSDate date].timeIntervalSinceReferenceDate - CACurrentMediaTime();
        _autoInstrumentRendering = true;
    }
    return self;
}

- (void)onAppEnteredBackground {
    self.isInForeground = false;
}

- (void)onAppEnteredForeground {
    self.isInForeground = true;
    self.justEnteredForeground = true;
    self.frameTimestampAdjustment = [NSDate date].timeIntervalSinceReferenceDate - CACurrentMediaTime();
}

- (FrameMetricsSnapshot *)currentSnapshot {
    @synchronized (self) {
        auto snapshot = [FrameMetricsSnapshot new];
        snapshot.totalFrames = self.totalFrames;
        snapshot.totalSlowFrames = self.totalSlowFrames;
        snapshot.totalFrozenFrames = self.totalFrozenFrames;
        snapshot.lastFrozenFrame = self.lastFrozenFrame;
        return snapshot;
    }
}

#pragma mark BSGPhasedStartup

- (void)earlyConfigure:(BSGEarlyConfiguration *)config {}

- (void)earlySetup {}

- (void)configure:(BugsnagPerformanceConfiguration *)config {
    self.autoInstrumentRendering = config.autoInstrumentRendering;
}

- (void)start {
    if (!self.autoInstrumentRendering) {
        return;
    }
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self
                                                             selector:@selector(didRenderFrame:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)preStartSetup {}

#pragma mark Private

- (void)didRenderFrame:(CADisplayLink *)sender {
    @synchronized (self) {
        if (!self.isInForeground) {
            return;
        }
        auto lastFrameTimestamp = self.lastFrameTimestamp;
        auto currentFrameTargetTimestamp = self.nextFrameTargetTimestamp;
        auto currentFrameTimestamp = sender.timestamp;
        
        self.lastFrameTimestamp = currentFrameTimestamp;
        self.nextFrameTargetTimestamp = sender.targetTimestamp;
        
        if (self.justEnteredForeground) {
            self.justEnteredForeground = false;
            return;
        }
        
        self.totalFrames++;
        
        auto renderDuration = currentFrameTimestamp - lastFrameTimestamp;
        if (renderDuration >= kFrozenFrameThreshold) {
            self.totalFrozenFrames++;
            FrozenFrameData *frameData = [[FrozenFrameData alloc] initWithStartTime:lastFrameTimestamp + self.frameTimestampAdjustment
                                                                            endTime:currentFrameTimestamp + self.frameTimestampAdjustment];
            self.lastFrozenFrame.next = frameData;
            self.lastFrozenFrame = frameData;
        } else {
            auto expectedRenderDuration = currentFrameTargetTimestamp - lastFrameTimestamp;
            if (renderDuration >= expectedRenderDuration * kSlowFrameRatioThreshold) {
                self.totalSlowFrames++;
            }
        }
    }
}

@end
