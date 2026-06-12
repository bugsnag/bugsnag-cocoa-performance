//
//  SessionMetricsAccumulator.h
//  BugsnagPerformance
//
//  Created by Meiyalagan Ramadurai on 05/06/26.
//  Copyright © 2026 Bugsnag. All rights reserved.
//
//
//  Created to fix data loss for long sessions (> ring buffer history).
//  Instead of relying on the ring buffer which only retains ~20 minutes of raw samples,
//  this accumulator maintains running min/max/sum/count in O(1) memory.
//  Every new sample from SystemInfoSampler is streamed here immediately.
//
//  For a 30-minute or 3-hour session the result is EXACT — no data loss, no chunking needed.
//

#pragma once

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <stdint.h>
#import <algorithm>
#import "SystemInfoSampler.h"

namespace bugsnag {

// ---------------------------------------------------------------------------
// Running stats for a single double metric (CPU percentages)
// ---------------------------------------------------------------------------
struct RunningDoubleStats {
    uint64_t count{0};
    double   sum{0.0};
    double   min{0.0};
    double   max{0.0};

    void addSample(double value) noexcept {
        if (count == 0) {
            min = value;
            max = value;
        } else {
            if (value < min) min = value;
            if (value > max) max = value;
        }
        sum += value;
        count++;
    }

    double mean() const noexcept {
        return count > 0 ? sum / (double)count : 0.0;
    }

    bool hasData() const noexcept { return count > 0; }
};

// ---------------------------------------------------------------------------
// Running stats for a single uint64_t metric (memory bytes)
// ---------------------------------------------------------------------------
struct RunningUInt64Stats {
    uint64_t count{0};
    uint64_t sum{0};
    uint64_t min{0};
    uint64_t max{0};
    uint64_t lastTotalSize{0}; // device total physical memory (for reporting)

    void addSample(uint64_t inUse, uint64_t totalSize) noexcept {
        if (count == 0) {
            min = inUse;
            max = inUse;
        } else {
            if (inUse < min) min = inUse;
            if (inUse > max) max = inUse;
        }
        sum += inUse;
        count++;
        lastTotalSize = totalSize;
    }

    uint64_t mean() const noexcept {
        return count > 0 ? sum / count : 0ULL;
    }

    bool hasData() const noexcept { return count > 0; }
};

// ---------------------------------------------------------------------------
// Accumulates CPU + memory running stats for one session span lifetime.
// Call addSample() for every new SystemInfoSampleData from the sampler.
// Call reset() when the session span ends and you've consumed the stats.
// ---------------------------------------------------------------------------
class SessionMetricsAccumulator {
public:
    // CPU stats
    RunningDoubleStats processCPU;
    RunningDoubleStats mainThreadCPU;
    RunningDoubleStats monitorThreadCPU;

    // Memory stats
    RunningUInt64Stats memory;

    // Session span start timestamp — only samples at or after this time are accepted.
    CFAbsoluteTime sessionStartTime{0};

    explicit SessionMetricsAccumulator(CFAbsoluteTime startTime = 0) noexcept
        : sessionStartTime(startTime)
    {}

    /// Feed one raw sample into the running stats.
    /// Samples before sessionStartTime are ignored.
    void addSample(const SystemInfoSampleData &sample) noexcept {
        if (!sample.isSampledAtValid()) { return; }
        if (sample.sampledAt < sessionStartTime)  { return; }

        if (sample.isProcessCPUPctValid()) {
            processCPU.addSample(sample.processCPUPct);
        }
        if (sample.isMainThreadCPUPctValid()) {
            mainThreadCPU.addSample(sample.mainThreadCPUPct);
        }
        if (sample.isMonitorThreadCPUPctValid()) {
            monitorThreadCPU.addSample(sample.monitorThreadCPUPct);
        }
        if (sample.isPhysicalMemoryInUseValid()) {
            memory.addSample(sample.physicalMemoryBytesInUse, sample.physicalMemoryBytesTotal);
        }
    }

    bool hasCPUData()    const noexcept { return processCPU.hasData() || mainThreadCPU.hasData() || monitorThreadCPU.hasData(); }
    bool hasMemoryData() const noexcept { return memory.hasData(); }

    void reset() noexcept {
        processCPU      = {};
        mainThreadCPU   = {};
        monitorThreadCPU = {};
        memory          = {};
    }
};

} // namespace bugsnag

