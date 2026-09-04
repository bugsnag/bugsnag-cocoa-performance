//
//  BSGDiskIOCollector.mm
//  BugsnagPerformance
//
//  Created by gaurav agarawal on 03/08/26.
//  Copyright © 2026 Bugsnag. All rights reserved.
//

#import "BSGDiskIOCollector.h"

#import "BSGDiskIOSnapshot.h"
#import "BSGDiskIOMetrics.h"
#import "../BugsnagPerformanceSpan+Private.h"

#include <cstdint>
#include <mutex>
#include <unordered_map>

NSString *const BSGDiskIOAttributeKeyIOPSRead = @"bugsnag.system.disk.iops_read";
NSString *const BSGDiskIOAttributeKeyIOPSWrite = @"bugsnag.system.disk.iops_write";
NSString *const BSGDiskIOAttributeKeyIOPSTotal = @"bugsnag.system.disk.iops_total";

// spanId is already a 64-bit identifier, so it is used directly as the map
// key. Formatting it into a string would add a heap allocation and a
// snprintf on every span start, end and abandon - measurable overhead for
// apps creating spans at a high rate.

@implementation BSGDiskIOCollector {
    std::unordered_map<uint64_t, BSGDiskIOSnapshot> _startSnapshots;
    std::mutex _mutex;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

- (void)onSpanStart:(BugsnagPerformanceSpan *)span {
    if (span == nil) {
        return;
    }
    if ((self.faultMode & BSGDiskIOSnapshotFaultModeFailAtStart) != 0) {
        // Test-only: behave exactly as if BSGCaptureDiskIOSnapshot() failed.
        return;
    }
    BSGDiskIOSnapshot snapshot = BSGCaptureDiskIOSnapshot();
    if (!snapshot.valid) {
        return;
    }
    std::lock_guard<std::mutex> lock(_mutex);
    _startSnapshots[(uint64_t)span.spanId] = snapshot;
}

- (NSDictionary<NSString *, NSNumber *> *)onSpanEnd:(BugsnagPerformanceSpan *)span {
    if (span == nil) {
        return nil;
    }

    // Capture the end snapshot immediately at span end, before any
    // subsequent processing (batching, callbacks, retry queue) can
    // move disk counters.
    BSGDiskIOSnapshot endSnapshot = BSGCaptureDiskIOSnapshot();

    BSGDiskIOSnapshot startSnapshot;
    bool hasStart = false;
    {
        std::lock_guard<std::mutex> lock(_mutex);
        auto it = _startSnapshots.find((uint64_t)span.spanId);
        if (it != _startSnapshots.end()) {
            startSnapshot = it->second;
            _startSnapshots.erase(it);
            hasStart = true;
        }
    }

    // Test-only fault injection. `faultMode` is
    // BSGDiskIOSnapshotFaultModeNone in production, so this block is inert
    // outside of e2e fixtures. Note that it deliberately runs *after* the
    // start snapshot has been erased above, so cleanup is still exercised on
    // every simulated failure path.
    BSGDiskIOSnapshotFaultMode faultMode = self.faultMode;
    if (faultMode != BSGDiskIOSnapshotFaultModeNone) {
        if ((faultMode & BSGDiskIOSnapshotFaultModeFailAtEnd) != 0) {
            endSnapshot.valid = false;
        }
        if (hasStart && (faultMode & BSGDiskIOSnapshotFaultModeZeroDuration) != 0) {
            endSnapshot.timestamp = startSnapshot.timestamp;
        }
        if (hasStart && (faultMode & BSGDiskIOSnapshotFaultModeNegativeDelta) != 0) {
            endSnapshot.bytesRead = startSnapshot.bytesRead > 0 ? startSnapshot.bytesRead - 1 : 0;
            endSnapshot.bytesWritten = startSnapshot.bytesWritten > 0 ? startSnapshot.bytesWritten - 1 : 0;
        }
    }

    if (!hasStart || !endSnapshot.valid) {
        return nil;
    }
    BSGDiskIOMetrics metrics = BSGComputeDiskIOMetrics(startSnapshot, endSnapshot);
    if (!metrics.valid) {
        return nil;
    }

    return @{
        BSGDiskIOAttributeKeyIOPSRead: @(metrics.iopsRead),
        BSGDiskIOAttributeKeyIOPSWrite: @(metrics.iopsWrite),
        BSGDiskIOAttributeKeyIOPSTotal: @(metrics.iopsTotal),
    };
}

- (void)abandonSpan:(BugsnagPerformanceSpan *)span {
    if (span == nil) {
        return;
    }
    std::lock_guard<std::mutex> lock(_mutex);
    _startSnapshots.erase((uint64_t)span.spanId);
}

- (NSUInteger)pendingSpanCount {
    std::lock_guard<std::mutex> lock(_mutex);
    return _startSnapshots.size();
}

#pragma clang diagnostic pop

@end
