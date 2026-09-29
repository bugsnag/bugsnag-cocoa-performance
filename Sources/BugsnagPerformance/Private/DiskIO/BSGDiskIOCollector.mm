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

NSString *const BSGDiskIODebugAttributeKeyReadStart = @"bugsnag.internal.disk_io.read_start";
NSString *const BSGDiskIODebugAttributeKeyReadEnd = @"bugsnag.internal.disk_io.read_end";
NSString *const BSGDiskIODebugAttributeKeyWriteStart = @"bugsnag.internal.disk_io.write_start";
NSString *const BSGDiskIODebugAttributeKeyWriteEnd = @"bugsnag.internal.disk_io.write_end";

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

    BSGDiskIOSnapshot startSnapshot;
    bool hasStart = false;
    {
        std::lock_guard<std::mutex> lock(_mutex);
        auto it = _startSnapshots.find((uint64_t)span.spanId);
        if (it != _startSnapshots.end()) {
            startSnapshot = it->second;
            hasStart = true;
        }
    }

    // The start snapshot is deliberately NOT erased here. A span's end time
    // can be moved later by a span condition (blocked spans), which re-runs
    // the end path; keeping the start snapshot lets each end recompute the
    // metrics over the span's real window. The entry is released by
    // -abandonSpan: once the span is final (processed, aborted or cancelled).
    //
    // Spans without a start snapshot (not disk-eligible, or disk metrics
    // disabled - the default) bail out before the end-snapshot capture so
    // they pay only a map lookup, not a proc_pid_rusage syscall.
    if (!hasStart) {
        return nil;
    }

    // Capture the end snapshot immediately once the span is known to be
    // disk-eligible, before any subsequent processing (batching, callbacks,
    // retry queue) can move disk counters.
    BSGDiskIOSnapshot endSnapshot = BSGCaptureDiskIOSnapshot();

    // Test-only fault injection. `faultMode` is
    // BSGDiskIOSnapshotFaultModeNone in production, so this block is inert
    // outside of e2e fixtures.
    BSGDiskIOSnapshotFaultMode faultMode = self.faultMode;
    if (faultMode != BSGDiskIOSnapshotFaultModeNone) {
        if ((faultMode & BSGDiskIOSnapshotFaultModeFailAtEnd) != 0) {
            endSnapshot.valid = false;
        }
        if ((faultMode & BSGDiskIOSnapshotFaultModeZeroDuration) != 0) {
            endSnapshot.timestamp = startSnapshot.timestamp;
        }
        if ((faultMode & BSGDiskIOSnapshotFaultModeNegativeDelta) != 0) {
            endSnapshot.bytesRead = startSnapshot.bytesRead > 0 ? startSnapshot.bytesRead - 1 : 0;
            endSnapshot.bytesWritten = startSnapshot.bytesWritten > 0 ? startSnapshot.bytesWritten - 1 : 0;
        }
    }

    if (!endSnapshot.valid) {
        return nil;
    }
    BSGDiskIOMetrics metrics = BSGComputeDiskIOMetrics(startSnapshot, endSnapshot);
    if (!metrics.valid) {
        return nil;
    }

    if (self.attachDebugSnapshots) {
        // Test-only: raw snapshot counters for snapshot-freshness assertions.
        // Cast to int64_t so the values encode as OTLP intValue like the
        // metrics themselves.
        return @{
            BSGDiskIOAttributeKeyIOPSRead: @(metrics.iopsRead),
            BSGDiskIOAttributeKeyIOPSWrite: @(metrics.iopsWrite),
            BSGDiskIOAttributeKeyIOPSTotal: @(metrics.iopsTotal),
            BSGDiskIODebugAttributeKeyReadStart: @((int64_t)startSnapshot.bytesRead),
            BSGDiskIODebugAttributeKeyReadEnd: @((int64_t)endSnapshot.bytesRead),
            BSGDiskIODebugAttributeKeyWriteStart: @((int64_t)startSnapshot.bytesWritten),
            BSGDiskIODebugAttributeKeyWriteEnd: @((int64_t)endSnapshot.bytesWritten),
        };
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
