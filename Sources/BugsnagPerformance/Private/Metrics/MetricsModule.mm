//
//  MetricsModule.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "MetricsModule.h"

using namespace bugsnag;

static constexpr double SAMPLER_INTERVAL_SECONDS = 1.0;
static constexpr double SAMPLER_HISTORY_SECONDS = 10 * 60;

#pragma mark PhasedStartup

void
MetricsModule::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    systemInfoSampler_->earlyConfigure(config);
    [frameMetricsCollector_ earlyConfigure:config];
}

void
MetricsModule::earlySetup() noexcept {
    systemInfoSampler_->earlySetup();
    [frameMetricsCollector_ earlySetup];
}

void
MetricsModule::configure(BugsnagPerformanceConfiguration *config) noexcept {
    systemInfoSampler_->configure(config);
    [frameMetricsCollector_ configure:config];
}

void
MetricsModule::preStartSetup() noexcept {
    systemInfoSampler_->preStartSetup();
    [frameMetricsCollector_ preStartSetup];
}

void
MetricsModule::start() noexcept {
    systemInfoSampler_->start();
    [frameMetricsCollector_ start];
}

#pragma mark Module

void MetricsModule::setUp() noexcept {
    frameMetricsCollector_ = [FrameMetricsCollector new];
    systemInfoSampler_ = std::make_shared<SystemInfoSampler>(SAMPLER_INTERVAL_SECONDS, SAMPLER_HISTORY_SECONDS);
}

#pragma mark Tasks

GetCurrentFrameMetricsSnapshot
MetricsModule::getCurrentFrameMetricsSnapshotTask() noexcept {
    __block auto blockThis = this;
    return ^FrameMetricsSnapshot *{
        if (blockThis->frameMetricsCollector_ == nullptr) {
            return nil;
        }
        return [blockThis->frameMetricsCollector_ currentSnapshot];
    };
}

#pragma mark AppLifecycleListener

void
MetricsModule::onAppEnteredBackground() noexcept {
    [frameMetricsCollector_ onAppEnteredBackground];
}

void
MetricsModule::onAppEnteredForeground() noexcept {
    [frameMetricsCollector_ onAppEnteredForeground];
}
