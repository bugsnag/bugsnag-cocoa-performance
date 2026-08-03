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

@interface BSGDiskIOCollector : NSObject

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

