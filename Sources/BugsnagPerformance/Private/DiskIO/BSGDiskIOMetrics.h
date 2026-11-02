//
//  BSGDiskIOMetrics.h
//  BugsnagPerformance
//
//  Created by gaurav agarawal on 03/08/26.
//  Copyright © 2026 Bugsnag. All rights reserved.
//

#pragma once

#import "BSGDiskIOSnapshot.h"

#include <cmath>
#include <cstdint>

struct BSGDiskIOMetrics {
    int64_t iopsRead{0};
    int64_t iopsWrite{0};
    int64_t iopsTotal{0};
    bool valid{false};
};

/// Compute a BSGDiskIOMetrics from two ordered snapshots.
///
/// proc_pid_rusage reports bytes transferred rather than operation counts, so
/// the byte delta is divided by the filesystem's block size (captured on the
/// snapshot, see BSGDiskBlockSizeBytes) to approximate the operation count.
///
/// Returns valid = false if either snapshot is invalid, if the duration
/// is not strictly positive, if the block size is not positive, or if either
/// byte counter regressed (end < start - a counter wrap or reset). A
/// regressed counter is a data-integrity signal, so the whole attribute set
/// is omitted rather than exporting synthetic values (PLAT-17202). A zero
/// delta is NOT a regression: an idle span validly exports 0/0/0.
static inline BSGDiskIOMetrics BSGComputeDiskIOMetrics(const BSGDiskIOSnapshot &start,
                                                       const BSGDiskIOSnapshot &end) noexcept {
    BSGDiskIOMetrics metrics;
    if (!start.valid || !end.valid) {
        return metrics;
    }

    double duration = end.timestamp - start.timestamp;
    if (duration <= 0.0) {
        return metrics;
    }

    // Both snapshots are taken in the same process against the same volume, so
    // the block size is expected to match. Use the end snapshot's value and
    // reject anything non-positive rather than dividing by zero.
    double blockSize = static_cast<double>(end.blockSize);
    if (blockSize <= 0.0) {
        return metrics;
    }

    // A counter that moved backwards means the underlying source regressed or
    // reset. Treat it like the other anomalous inputs above: omit the whole
    // attribute set rather than exporting values that may be wrong.
    if (end.bytesRead < start.bytesRead || end.bytesWritten < start.bytesWritten) {
        return metrics;
    }

    uint64_t readDelta = end.bytesRead - start.bytesRead;
    uint64_t writeDelta = end.bytesWritten - start.bytesWritten;

    double readOpsPerSec = (static_cast<double>(readDelta) / blockSize) / duration;
    double writeOpsPerSec = (static_cast<double>(writeDelta) / blockSize) / duration;

    metrics.iopsRead = static_cast<int64_t>(std::llround(readOpsPerSec));
    metrics.iopsWrite = static_cast<int64_t>(std::llround(writeOpsPerSec));
    metrics.iopsTotal = metrics.iopsRead + metrics.iopsWrite;
    metrics.valid = true;
    return metrics;
}
