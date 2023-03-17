//
//  RetryQueue.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 17.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import "OtlpPackage.h"
#import <vector>
#import <memory>

namespace bugsnag {


class RetryQueue {
public:
    RetryQueue(NSString *path) noexcept;
    RetryQueue() = delete;

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

private:
    NSString *baseDir_{nil};
    void (^onFilesystemError)(){nullptr};

    void remove(NSString *filename) noexcept;
    NSString *fullPath(NSString *filename) noexcept;
    void ensureBaseDirExists() noexcept;
};

}
