//
//  RetryQueue.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 17.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import "OtlpPackage.h"
#import "PhasedStartup.h"
#import <vector>
#import <memory>

namespace bugsnag {


class RetryQueue: public PhasedStartup {
public:
    RetryQueue() = delete;
    RetryQueue(NSString *path) noexcept
    : baseDir_(path)
    , onFilesystemError(^{})
    {}

    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept;
    void start() noexcept {}

    /**
     * Sweep the retry queue, deleting any non-retry files and retries that are older than 24 hours.
     */
    void sweep() noexcept;

    /**
     * List the timestamps of all retries in the queue, listing newest first.
     */
    std::vector<dispatch_time_t> list() noexcept;

    /**
     * Get a retry by its timestamp.
     * Returns nullptr if no such retry exists.
     */
    std::unique_ptr<OtlpPackage> get(dispatch_time_t ts) noexcept;

    /**
     * Add a package to the retry queue.
     */
    void add(OtlpPackage &package) noexcept;

    /**
     * Remove a retry.
     * Note: Does not call onFilesystemError.
     */
    void remove(dispatch_time_t ts) noexcept;

    /**
     * Set a callback to call on any unexpected filesystem error.
     */
    void setOnFilesystemError(void (^onFilesystemErrorCallback)()) {
        onFilesystemError = onFilesystemErrorCallback;
    }

    /**
     * Disable any filesystem IO performed by the retry queue (used in tests/fixtures).
     */
    void disableFilesystemIO() noexcept;

    /**
     * Returns whether filesystem IO is disabled.
     */
    bool filesystemIODisabled() noexcept;

private:
    NSString *baseDir_{nil};
    dispatch_time_t maxRetryAge_{0};
    void (^onFilesystemError)(){nullptr};
    bool filesystemIODisabled_{false};

    void remove(NSString *filename) noexcept;
    NSString *fullPath(NSString *filename) noexcept;
    void ensureBaseDirExists() noexcept;
};

}
