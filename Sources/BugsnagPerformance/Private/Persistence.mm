//
//  Persistence.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#define BUGSNAG_PERFORMANCE_PERSISTENCE_VERSION @"v1"

#import "Persistence.h"
#import "Filesystem.h"
#import "Utils.h"
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <limits.h>

using namespace bugsnag;

static NSString *bugsnagPerformancePath(NSString *topLevelDir) {
    // Namespace it to the bundle identifier because all MacOS non-sandboxed apps share the same cache dir.
    return [topLevelDir stringByAppendingFormat:@"/bugsnag-performance-%@", [[NSBundle mainBundle] bundleIdentifier]];
}

static NSString *bugsnagSharedPath(NSString *topLevelDir) {
    return [topLevelDir stringByAppendingFormat:@"/bugsnag-shared-%@", [[NSBundle mainBundle] bundleIdentifier]];
}

// Helper: ensure the directory exists (Filesystem) and verify we can write a small test file.
// Returns true if writable (or created and writable), false otherwise.
static bool ensurePathExistsAndWritable(NSString *dirPath, const char *testFileName, const char *logLabel) {
    NSError *err = nil;
    if ((err = [Filesystem ensurePathExists:dirPath]) != nil) {
        BSGLogDebug(@"Persistence ctor: failed to create %s %@: %@", logLabel, dirPath, err);
        return false;
    }

    // Build C test path into a stack buffer to avoid NSString allocations.
    const char *base = [dirPath fileSystemRepresentation];
    if (base == NULL) {
        BSGLogDebug(@"Persistence ctor: unable to get fileSystemRepresentation for %s %@", logLabel, dirPath);
        return false;
    }

    // Fast-path: if the directory is writable per access(), avoid doing a write test.
    // access() is cheap and sufficient for the common case; if it indicates not writable,
    // fall back to the more reliable write test.
    if (access(base, W_OK) == 0) {
        return true;
    }

    char cpath[PATH_MAX];
    // Ensure we don't overflow PATH_MAX; snprintf truncates if necessary.
    int n = snprintf(cpath, sizeof(cpath), "%s/%s", base, testFileName);
    if (n < 0 || (size_t)n >= sizeof(cpath)) {
        BSGLogDebug(@"Persistence ctor: test path too long for %s %@", logLabel, dirPath);
        return false;
    }

    // Open with user-only permissions and close-on-exec to be robust and minimal.
    int fd = open(cpath, O_CREAT | O_TRUNC | O_WRONLY | O_CLOEXEC, S_IRUSR | S_IWUSR);
    if (fd < 0) {
        int e = errno;
        BSGLogDebug(@"Persistence ctor: open(%s) failed for %s %@: errno=%d (%s)", testFileName, logLabel, dirPath, e, strerror(e));
        return false;
    }

    ssize_t wrote = write(fd, "t", 1);
    int savedErr = errno;
    close(fd);

    if (wrote != 1) {
        BSGLogDebug(@"Persistence ctor: write failed for %s %@: errno=%d (%s)", logLabel, dirPath, savedErr, strerror(savedErr));
        // best-effort cleanup
        unlink(cpath);
        return false;
    }

    // Cleanup
    unlink(cpath);
    return true;
}

Persistence::Persistence(NSString *topLevelDir) noexcept
: bugsnagSharedDir_(bugsnagSharedPath(topLevelDir))
, bugsnagPerformanceDir_(bugsnagPerformancePath(topLevelDir))
{
    bool usable = true;

    BSGLogDebug(@"Persistence ctor: topLevelDir=%@", topLevelDir);
    BSGLogDebug(@"Persistence ctor: computed performanceDir=%@", bugsnagPerformanceDir_);
    BSGLogDebug(@"Persistence ctor: computed sharedDir=%@", bugsnagSharedDir_);

    // Check performance top-level, versioned dir, and retry-queue
    if (!ensurePathExistsAndWritable(bugsnagPerformanceDir_, ".bsg_write_test", "performance dir")) {
        usable = false;
    } else {
        NSString *versionedDir = [bugsnagPerformanceDir_ stringByAppendingPathComponent:BUGSNAG_PERFORMANCE_PERSISTENCE_VERSION];
        if (!ensurePathExistsAndWritable(versionedDir, ".bsg_write_test_versioned", "versioned performance dir")) {
            usable = false;
        } else {
            NSString *retryQueueDir = [versionedDir stringByAppendingPathComponent:@"retry-queue"];
            if (!ensurePathExistsAndWritable(retryQueueDir, ".bsg_write_test_retry", "retry-queue dir")) {
                usable = false;
            }
        }
    }

    // Check shared dir
    if (!ensurePathExistsAndWritable(bugsnagSharedDir_, ".bsg_write_test_shared", "shared dir")) {
        usable = false;
    }

    isUsable_.store(usable, std::memory_order_release);
}

void Persistence::start() noexcept {
    NSError *error = nil;
    bool usable = true;

    if ((error = [Filesystem ensurePathExists:bugsnagPerformanceDir_]) != nil) {
        BSGLogError(@"error while initializing bugsnag performance persistence dir: %@", error);
        usable = false;
    }
    if ((error = [Filesystem ensurePathExists:bugsnagSharedDir_]) != nil) {
        BSGLogError(@"error while initializing bugsnag shared persistence dir: %@", error);
        usable = false;
    }

    // If we can't create the top-level directories, persistence-backed features can't work.
    // The library should continue running in network-only mode, but must avoid repeated failing I/O.
    isUsable_.store(usable, std::memory_order_release);
}

NSString *Persistence::bugsnagSharedDir(void) noexcept {
    return bugsnagSharedDir_;
}

NSString *Persistence::bugsnagPerformanceDir(void) noexcept {
    return [bugsnagPerformanceDir_ stringByAppendingPathComponent:BUGSNAG_PERFORMANCE_PERSISTENCE_VERSION];
}

NSError *Persistence::clearPerformanceData(void) noexcept {
    return [Filesystem rebuildPath:bugsnagPerformanceDir_];

    // Note: We don't clear bugsnagSharedDir_ because it's shared with the bugsnag notifier.
}
