//
//  Persistence.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#include <atomic>

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

class Persistence {
public:
    Persistence() = delete;
    Persistence(NSString *topLevelDir) noexcept;

    void start() noexcept;

    /**
     * Returns true if the SDK's persistence directories were successfully created and are usable.
     * When false, file-backed features (retry queue, persistent state/device id) should be disabled
     * to avoid repeated failing filesystem operations.
     */
    bool isUsable(void) const noexcept { return isUsable_.load(std::memory_order_acquire); }

    // Clear all "performance" data. "shared" data is unaffected.
    NSError *clearPerformanceData(void) noexcept;

    // "performance" dir is for regular bugsnag-performance persistent data, and is versioned.
    NSString *bugsnagPerformanceDir(void) noexcept;

    // "shared" dir is shared between bugsnag and bugsnag-persistence. It is *not* versioned!
    NSString *bugsnagSharedDir(void) noexcept;

private:
    NSString *bugsnagSharedDir_{nil};
    NSString *bugsnagPerformanceDir_{nil};
    std::atomic<bool> isUsable_{true};
};

}

NS_ASSUME_NONNULL_END
