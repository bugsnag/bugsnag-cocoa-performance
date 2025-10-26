//
//  SystemInfoSampler.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 15.01.25.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <vector>
#import <mutex>
#import "BSGPSystemInfo.h"
#import "../../Utils/FixedLengthDequeue.h"
#import "../../Core/PhasedStartup.h"

namespace bugsnag {

struct SystemInfoSampleData {
    SystemInfoSampleData() {}
    SystemInfoSampleData(CFAbsoluteTime sampledAtTime)
    : sampledAt(sampledAtTime)
    {}

    CFAbsoluteTime sampledAt{-1};
    double processCPUPct{-1};
    double mainThreadCPUPct{-1};
    double monitorThreadCPUPct{-1};
    uint64_t physicalMemoryBytesTotal{0};
    uint64_t physicalMemoryBytesInUse{0};

    bool isSampledAtValid()           const { return sampledAt > 0; }
    bool isProcessCPUPctValid()       const { return processCPUPct >= 0; }
    bool isMainThreadCPUPctValid()    const { return mainThreadCPUPct >= 0; }
    bool isMonitorThreadCPUPctValid() const { return monitorThreadCPUPct >= 0; }
    bool isPhysicalMemoryInUseValid() const { return physicalMemoryBytesInUse > 0; }

    bool hasValidCPUData() const {
        return isProcessCPUPctValid() ||
        isMainThreadCPUPctValid() ||
        isMonitorThreadCPUPctValid();
    }

    bool hasValidMemoryData() const {
        return isPhysicalMemoryInUseValid();
    }

    bool hasValidData() {
        if (!isSampledAtValid()) {
            return false;
        }
        return hasValidCPUData() || hasValidMemoryData();
    }

    static struct {
        bool operator() (const SystemInfoSampleData &left, const CFAbsoluteTime &right) const {
            return left.sampledAt < right;
        }
    } CompareSampledAtLower;
    static struct {
        bool operator() (const CFAbsoluteTime &left, const SystemInfoSampleData &right) const {
            return left < right.sampledAt;
        }
    } CompareSampledAtUpper;
};

class SystemInfoSampler: public PhasedStartup {
public:
    SystemInfoSampler(NSTimeInterval samplePeriod, NSTimeInterval historyDuration)
    : samplePeriod_(samplePeriod)
    , samples_((size_t)(historyDuration*2.0/samplePeriod)) // Collect double what we'll be using
    {}
    virtual ~SystemInfoSampler() {}

    // Phased Startup
    virtual void earlyConfigure(BSGEarlyConfiguration *) noexcept;
    virtual void earlySetup() noexcept;
    virtual void configure(BugsnagPerformanceConfiguration *config) noexcept;
    virtual void preStartSetup() noexcept {};
    virtual void start() noexcept {};

    /**
     * Collect any sampled data around the time range specified (1 sample prior to the start, and 1 sample after the end).
     */
    std::vector<SystemInfoSampleData> samplesAroundTimePeriod(CFAbsoluteTime startTime, CFAbsoluteTime endTime);

private:
    CFAbsoluteTime calculateAppStartTime();
    void recordSample();

private:
    std::mutex samplesMutex_;
    std::mutex recordMutex_;
    BSGPSystemInfo systemInfo_;
    FixedLengthDequeue<SystemInfoSampleData> samples_;

    // Set in constructor
    NSTimeInterval samplePeriod_;

    // These require "zeroed" defaults
    mach_port_t mainThread_{0};
    NSThread *samplerThread_{nil};
    bool shouldAbortSamplerThread_{false};

    // These start off enabled until disabled via config
    bool shouldSampleCPU_{true};
    bool shouldSampleMemory_{true};

    // Cached sampling checkpoints
    CFAbsoluteTime lastSampledAtTime_{0};
    time_value_t lastSampleProcessCPU_{0};
    time_value_t lastSampleMainThreadCPU_{0};
    time_value_t lastSampleMonitorThreadCPU_{0};
};

}
