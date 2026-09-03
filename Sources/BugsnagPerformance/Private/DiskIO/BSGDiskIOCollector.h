//
//  BSGDiskIOCollector.h
//  BugsnagPerformance
//
//  Created by gaurav agarawal on 03/08/26.
//  Copyright © 2026 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

@class BugsnagPerformanceSpan;

NS_ASSUME_NONNULL_BEGIN

/// The three attribute keys written by the collector on span end.
/// All three are optional — if the platform source is unavailable or the
/// span duration is <= 0, the collector returns nil and no attributes are
/// added to the span.
extern NSString *const BSGDiskIOAttributeKeyIOPSRead;
extern NSString *const BSGDiskIOAttributeKeyIOPSWrite;
extern NSString *const BSGDiskIOAttributeKeyIOPSTotal;

/// Test-only fault injection.
///
/// The platform snapshot source (`proc_pid_rusage`) cannot be made to fail on
/// demand, so the negative paths of the collector are unreachable from an
/// end-to-end fixture. These flags let the e2e fixtures drive those paths
/// through the *real* span lifecycle and exporter.
///
/// `BSGDiskIOSnapshotFaultModeNone` is the default and is what production
/// always uses — the injection block in `-onSpanEnd:` is inert unless a fault
/// mode is explicitly set via `BSGInternalConfiguration.diskIOSnapshotFaultMode`.
typedef NS_OPTIONS(NSUInteger, BSGDiskIOSnapshotFaultMode) {
    /// Normal production behaviour.
    BSGDiskIOSnapshotFaultModeNone          = 0,
    /// Skip storing the start snapshot, as if the platform read failed.
    BSGDiskIOSnapshotFaultModeFailAtStart   = 1 << 0,
    /// Mark the end snapshot invalid, as if the platform read failed.
    BSGDiskIOSnapshotFaultModeFailAtEnd     = 1 << 1,
    /// Force `end.timestamp == start.timestamp` so duration <= 0.
    BSGDiskIOSnapshotFaultModeZeroDuration  = 1 << 2,
    /// Force `end.bytes* < start.bytes*` to exercise the counter-regression path.
    BSGDiskIOSnapshotFaultModeNegativeDelta = 1 << 3,
};

@interface BSGDiskIOCollector : NSObject

/// Test-only. Defaults to `BSGDiskIOSnapshotFaultModeNone`.
@property (atomic, assign) BSGDiskIOSnapshotFaultMode faultMode;

/// Capture the start snapshot for a span. Silently no-ops if the platform
/// source is unavailable — the matching -onSpanEnd: will then return nil.
- (void)onSpanStart:(BugsnagPerformanceSpan *)span;

/// Capture the end snapshot immediately, retrieve+remove the start
/// snapshot under a lock, and compute the IOPS metrics.
///
/// Returns a dictionary keyed by the three BSGDiskIOAttributeKey* keys
/// whose values are int64_t NSNumbers, or nil if no valid metrics could
/// be computed (missing start snapshot, invalid platform read, or
/// duration <= 0).
- (nullable NSDictionary<NSString *, NSNumber *> *)onSpanEnd:(BugsnagPerformanceSpan *)span;

/// Drop any stored start snapshot for a span that will never end.
/// Called for cancelled / discarded spans to keep the map bounded.
- (void)abandonSpan:(BugsnagPerformanceSpan *)span;

/// Testing only — number of pending start snapshots currently held.
- (NSUInteger)pendingSpanCount;

@end

NS_ASSUME_NONNULL_END

