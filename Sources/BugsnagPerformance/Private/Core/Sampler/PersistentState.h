//
//  PersistentState.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import "../PhasedStartup.h"
#import "../../Utils/Persistence.h"

#import <Foundation/Foundation.h>
#import <mutex>
#import <memory>

namespace bugsnag {

class PersistentState: PhasedStartup {
public:
    PersistentState() = delete;
    PersistentState(std::shared_ptr<Persistence> persistence) noexcept
    : persistence_(persistence)
    {}

    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *) noexcept;
    void preStartSetup() noexcept;
    void start() noexcept {}

    void setProbability(double probability) noexcept;
    double probability(void) noexcept {return probability_;};

private:
    std::mutex mutex_;
    std::shared_ptr<Persistence> persistence_;
    NSString *jsonFilePath_{nil};
    NSString *persistentStateDir_{nil};
    double probability_{1.0};

    NSError *persist() noexcept;
};

}
