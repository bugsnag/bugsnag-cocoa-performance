//
//  BSGDiskIOSnapshot.h
//  BugsnagPerformance
//
//  Created by gaurav agarawal on 03/08/26.
//  Copyright © 2026 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

#import <sys/mount.h>
#import <sys/param.h>
#import <sys/resource.h>
#import <unistd.h>

#include <cstdint>

// libproc.h is not in the iOS public SDK, so forward-declare the single
// entry point we need. The symbol resolves at runtime via libSystem,
// where proc_pid_rusage has always been available.
#ifdef __cplusplus
extern "C" {
#endif
int proc_pid_rusage(int pid, int flavor, rusage_info_t *buffer);
#ifdef __cplusplus
}
#endif

/// Fallback used when statfs() is unavailable. APFS on iOS reports a 4 KB
/// native block size (f_bsize); this matches that so the fallback does not
/// silently skew the derived operation count.
constexpr uint32_t kBSGFallbackDiskBlockSizeBytes = 4096;

/// The filesystem's native block size, read once per process.
///
/// proc_pid_rusage reports bytes transferred, not operation counts, so the
/// byte delta is divided by this to approximate operations. Reading the real
/// f_bsize avoids the 4x under-reporting that a hardcoded 16 KB "allocation
/// cluster" size would produce on device. statfs is called at most once -
/// calling it per snapshot would add a syscall to every span start and end.
static inline uint32_t BSGDiskBlockSizeBytes() noexcept {
    static uint32_t blockSize = []() -> uint32_t {
        struct statfs sfs;
        if (statfs([NSTemporaryDirectory() fileSystemRepresentation], &sfs) == 0 &&
            sfs.f_bsize > 0) {
            return (uint32_t)sfs.f_bsize;
        }
        return kBSGFallbackDiskBlockSizeBytes;
    }();
    return blockSize;
}

struct BSGDiskIOSnapshot {
    CFAbsoluteTime timestamp{0};
    uint64_t bytesRead{0};
    uint64_t bytesWritten{0};
    /// Filesystem block size in bytes at the time of capture. Defaults to the
    /// fallback so unit tests constructing snapshots by hand get a sane value.
    uint32_t blockSize{kBSGFallbackDiskBlockSizeBytes};
    bool valid{false};
};

/// Capture a disk-I/O snapshot for the current process.
///
/// Uses proc_pid_rusage(RUSAGE_INFO_V4) to read ri_diskio_bytesread and
/// ri_diskio_byteswritten. On failure (non-zero return) the returned
/// snapshot has valid = false and disk metrics are omitted for the span.
static inline BSGDiskIOSnapshot BSGCaptureDiskIOSnapshot() noexcept {
    BSGDiskIOSnapshot snapshot;
    snapshot.timestamp = CFAbsoluteTimeGetCurrent();
    snapshot.blockSize = BSGDiskBlockSizeBytes();

    rusage_info_current info{};
    int rc = proc_pid_rusage(getpid(), RUSAGE_INFO_V4, (rusage_info_t *)&info);
    if (rc != 0) {
        return snapshot;
    }

    snapshot.bytesRead = info.ri_diskio_bytesread;
    snapshot.bytesWritten = info.ri_diskio_byteswritten;
    snapshot.valid = true;
    return snapshot;
}
