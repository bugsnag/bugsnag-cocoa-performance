//
//  MetricsModule.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "../Core/Module.h"
#import "../Core/AppLifecycleListener.h"
#import "FrameMetrics/FrameMetricsCollector.h"
#import "SystemMetrics/SystemInfoSampler.h"

#import <memory>

namespace bugsnag {
class MetricsModule: public Module, public AppLifecycleListener {
public:
    MetricsModule() {};
    
    ~MetricsModule() {};
    
    void earlyConfigure(BSGEarlyConfiguration *config) noexcept;
    void earlySetup() noexcept;
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept;
    void start() noexcept;
    
    void setUp() noexcept;
    
    void onAppFinishedLaunching() noexcept {}
    void onAppEnteredBackground() noexcept;
    void onAppEnteredForeground() noexcept;
    
    double getSamplerInterval() noexcept;
    
    // Tasks
    
    GetCurrentFrameMetricsSnapshot getCurrentFrameMetricsSnapshotTask() noexcept;
    
    
    // Components access
    
    FrameMetricsCollector *getFrameMetricsCollector() noexcept { return frameMetricsCollector_; }
    std::shared_ptr<SystemInfoSampler> getSystemInfoSampler() noexcept { return systemInfoSampler_; }
    
private:
    
    // Components
    std::shared_ptr<SystemInfoSampler> systemInfoSampler_;
    FrameMetricsCollector *frameMetricsCollector_;
};
}
