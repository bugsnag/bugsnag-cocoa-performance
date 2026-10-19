//
//  BSGDiskIOSnapshot.h
//  BugsnagPerformance
//
//  Created by gaurav agarawal on 03/08/26.
//  Copyright © 2026 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

#import <sys/resource.h>
#import <unistd.h>

#include <cstdint>
#include <dlfcn.h>
#include <time.h>

// libproc.h is not in the iOS public SDK, so proc_pid_rusage is looked up
// by name at first use instead of being linked directly. A direct reference
// would make the framework fail to load (dyld "symbol not found") on any
// runtime whose libSystem does not export it, which would take the whole app
// down. With dlsym a missing symbol simply yields an invalid snapshot and the
// disk attributes are omitted for the span.
typedef int (*BSGProcPidRusageFn)(int pid, int flavor, rusage_info_t *buffer);

inline BSGProcPidRusageFn BSGProcPidRusage() noexcept {
    static BSGProcPidRusageFn fn = (BSGProcPidRusageFn)dlsym(RTLD_DEFAULT, "proc_pid_rusage");
    return fn;
}

/// The block size used to turn bytes into an approximate operation count: APFS, the only iOS filesystem, reports a
/// 4 KB native block size (f_bsize). A constant rather than statfs(): statfs is an Apple "required reason" API
/// (NSPrivacyAccessedAPICategoryDiskSpace), which would need a declaration in the privacy manifest of every app
/// shipping the SDK, only to read a value that is always 4096 on iOS.
constexpr uint32_t kBSGDiskBlockSizeBytes = 4096;

/// Kept as a function so callers and tests read the block size in one place.
inline uint32_t BSGDiskBlockSizeBytes() noexcept {
    return kBSGDiskBlockSizeBytes;
}

/// Monotonic seconds since boot. The snapshot timestamps only ever feed a
/// duration, and the span's own duration is computed from the monotonic clock
/// to defeat wall-clock adjustments, so the disk window must be too: an NTP
/// or user clock jump during a span would otherwise skew or negate the IOPS.
inline double BSGDiskIOMonotonicSeconds() noexcept {
    struct timespec ts{};
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
        return 0;
    }
    return (double)ts.tv_sec + (double)ts.tv_nsec / 1e9;
}

struct BSGDiskIOSnapshot {
    /// Monotonic seconds (see BSGDiskIOMonotonicSeconds), not wall-clock time.
    double timestamp{0};
    uint64_t bytesRead{0};
    uint64_t bytesWritten{0};
    /// Block size in bytes (kBSGDiskBlockSizeBytes); unit tests constructing
    /// snapshots by hand get the same value.
    uint32_t blockSize{kBSGDiskBlockSizeBytes};
    bool valid{false};
};

/// Capture a disk-I/O snapshot for the current process.
///
/// Uses proc_pid_rusage(RUSAGE_INFO_V4) to read ri_diskio_bytesread and
/// ri_diskio_byteswritten. On failure (non-zero return) the returned
/// snapshot has valid = false and disk metrics are omitted for the span.
inline BSGDiskIOSnapshot BSGCaptureDiskIOSnapshot() noexcept {
    BSGDiskIOSnapshot snapshot;
    snapshot.timestamp = BSGDiskIOMonotonicSeconds();
    snapshot.blockSize = BSGDiskBlockSizeBytes();

    BSGProcPidRusageFn procPidRusage = BSGProcPidRusage();
    if (procPidRusage == nullptr) {
        return snapshot;
    }
    rusage_info_current info{};
    int rc = procPidRusage(getpid(), RUSAGE_INFO_V4, (rusage_info_t *)&info);
    if (rc != 0) {
        return snapshot;
    }

    snapshot.bytesRead = info.ri_diskio_bytesread;
    snapshot.bytesWritten = info.ri_diskio_byteswritten;
    snapshot.valid = true;
    return snapshot;
}
