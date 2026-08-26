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

#include <cstdio>
#include <mutex>
#include <string>
#include <unordered_map>

NSString *const BSGDiskIOAttributeKeyIOPSRead = @"bugsnag.system.disk.iops_read";
NSString *const BSGDiskIOAttributeKeyIOPSWrite = @"bugsnag.system.disk.iops_write";
NSString *const BSGDiskIOAttributeKeyIOPSTotal = @"bugsnag.system.disk.iops_total";

namespace {
std::string spanKey(BugsnagPerformanceSpan *span) {
    // spanId is a 64-bit identifier; format as a fixed-width hex string
    // so ordering and equality match the wire representation.
    char buf[17];
    std::snprintf(buf, sizeof(buf), "%016llx", (unsigned long long)span.spanId);
    return std::string(buf);
}
}

@implementation BSGDiskIOCollector {
    std::unordered_map<std::string, BSGDiskIOSnapshot> _startSnapshots;
    std::mutex _mutex;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

- (void)onSpanStart:(BugsnagPerformanceSpan *)span {
    if (span == nil) {
        return;
    }
    BSGDiskIOSnapshot snapshot = BSGCaptureDiskIOSnapshot();
    if (!snapshot.valid) {
        return;
    }
    std::string key = spanKey(span);
    std::lock_guard<std::mutex> lock(_mutex);
    _startSnapshots[key] = snapshot;
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
        std::string key = spanKey(span);
        std::lock_guard<std::mutex> lock(_mutex);
        auto it = _startSnapshots.find(key);
        if (it != _startSnapshots.end()) {
            startSnapshot = it->second;
            _startSnapshots.erase(it);
            hasStart = true;
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
    std::string key = spanKey(span);
    std::lock_guard<std::mutex> lock(_mutex);
    _startSnapshots.erase(key);
}

- (NSUInteger)pendingSpanCount {
    std::lock_guard<std::mutex> lock(_mutex);
    return _startSnapshots.size();
}

#pragma clang diagnostic pop

@end
