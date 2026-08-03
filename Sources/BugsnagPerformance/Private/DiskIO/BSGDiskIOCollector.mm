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
#import "../Logging.h"  // TEMP: flow logs

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
        BSGLogInfo(@"[DiskIO] Step 1/onSpanStart: skipped (span=nil)");
        return;
    }
    BSGDiskIOSnapshot snapshot = BSGCaptureDiskIOSnapshot();
    if (!snapshot.valid) {
        BSGLogInfo(@"[DiskIO] Step 1/onSpanStart: proc_pid_rusage failed for span=%@ (spanId=%016llx) -- start snapshot NOT stored",
                   span.name, (unsigned long long)span.spanId);
        return;
    }
    std::string key = spanKey(span);
    {
        std::lock_guard<std::mutex> lock(_mutex);
        _startSnapshots[key] = snapshot;
    }
    BSGLogInfo(@"[DiskIO] Step 1/onSpanStart: START snapshot stored -- span=%@ (spanId=%016llx) t=%.4f bytesRead=%llu bytesWritten=%llu pending=%zu",
               span.name,
               (unsigned long long)span.spanId,
               snapshot.timestamp,
               (unsigned long long)snapshot.bytesRead,
               (unsigned long long)snapshot.bytesWritten,
               _startSnapshots.size());
}

- (NSDictionary<NSString *, NSNumber *> *)onSpanEnd:(BugsnagPerformanceSpan *)span {
    if (span == nil) {
        BSGLogInfo(@"[DiskIO] Step 2/onSpanEnd: skipped (span=nil)");
        return nil;
    }

    // Capture the end snapshot immediately at span end, before any
    // subsequent processing (batching, callbacks, retry queue) can
    // move disk counters.
    BSGDiskIOSnapshot endSnapshot = BSGCaptureDiskIOSnapshot();
    BSGLogInfo(@"[DiskIO] Step 2/onSpanEnd: END snapshot captured -- span=%@ (spanId=%016llx) valid=%d t=%.4f bytesRead=%llu bytesWritten=%llu",
               span.name,
               (unsigned long long)span.spanId,
               endSnapshot.valid ? 1 : 0,
               endSnapshot.timestamp,
               (unsigned long long)endSnapshot.bytesRead,
               (unsigned long long)endSnapshot.bytesWritten);

    BSGDiskIOSnapshot startSnapshot;
    bool hasStart = false;
    size_t remaining = 0;
    {
        std::string key = spanKey(span);
        std::lock_guard<std::mutex> lock(_mutex);
        auto it = _startSnapshots.find(key);
        if (it != _startSnapshots.end()) {
            startSnapshot = it->second;
            _startSnapshots.erase(it);
            hasStart = true;
        }
        remaining = _startSnapshots.size();
    }
    BSGLogInfo(@"[DiskIO] Step 3/onSpanEnd: retrieved matching start for span=%@ hasStart=%d pending=%zu",
               span.name, hasStart ? 1 : 0, remaining);

    if (!hasStart || !endSnapshot.valid) {
        BSGLogInfo(@"[DiskIO] Step 4/onSpanEnd: no metrics emitted (hasStart=%d endValid=%d) -- span=%@",
                   hasStart ? 1 : 0, endSnapshot.valid ? 1 : 0, span.name);
        return nil;
    }

    BSGDiskIOMetrics metrics = BSGComputeDiskIOMetrics(startSnapshot, endSnapshot);
    if (!metrics.valid) {
        BSGLogInfo(@"[DiskIO] Step 4/onSpanEnd: metrics INVALID (duration<=0 or bad snapshot) -- span=%@ startT=%.4f endT=%.4f",
                   span.name, startSnapshot.timestamp, endSnapshot.timestamp);
        return nil;
    }

    BSGLogInfo(@"[DiskIO] Step 4/onSpanEnd: emitting attributes -- span=%@ duration=%.4fs iops_read=%lld iops_write=%lld iops_total=%lld",
               span.name,
               endSnapshot.timestamp - startSnapshot.timestamp,
               (long long)metrics.iopsRead,
               (long long)metrics.iopsWrite,
               (long long)metrics.iopsTotal);

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
    size_t erased = 0;
    size_t remaining = 0;
    {
        std::lock_guard<std::mutex> lock(_mutex);
        erased = _startSnapshots.erase(key);
        remaining = _startSnapshots.size();
    }
    BSGLogInfo(@"[DiskIO] abandonSpan (cancelled/discarded) -- span=%@ (spanId=%016llx) erased=%zu pending=%zu",
               span.name,
               (unsigned long long)span.spanId,
               erased,
               remaining);
}

- (NSUInteger)pendingSpanCount {
    std::lock_guard<std::mutex> lock(_mutex);
    return _startSnapshots.size();
}

#pragma clang diagnostic pop

@end
