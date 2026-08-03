//
//  BSGDiskIOSnapshot.h
//  BugsnagPerformance
//
//  Created by gaurav agarawal on 03/08/26.
//  Copyright © 2026 Bugsnag. All rights reserved.
//

#pragma once

#import <CoreFoundation/CoreFoundation.h>

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

struct BSGDiskIOSnapshot {
    CFAbsoluteTime timestamp{0};
    uint64_t bytesRead{0};
    uint64_t bytesWritten{0};
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
