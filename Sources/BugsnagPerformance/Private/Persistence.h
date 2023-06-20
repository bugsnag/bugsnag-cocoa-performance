//
//  Persistence.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

namespace bugsnag {

class Persistence {
public:
    Persistence() = delete;
    Persistence(NSString *topLevelDir) noexcept;

    void start() noexcept;

    // Clear all "performance" data. "shared" data is unaffected.
    NSError *clearPerformanceData(void) noexcept;

    // "performance" dir is for regular bugsnag-performance persistent data, and is versioned.
    NSString *bugsnagPerformanceDir(void) noexcept;

    // "shared" dir is shared between bugsnag and bugsnag-persistence. It is *not* versioned!
    NSString *bugsnagSharedDir(void) noexcept;

private:
    NSString *bugsnagSharedDir_{nil};
    NSString *bugsnagPerformanceDir_{nil};
};

}
