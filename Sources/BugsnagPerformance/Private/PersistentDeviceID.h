//
//  PersistentDeviceID.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 16.06.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import "PhasedStartup.h"
#import "Persistence.h"
#import <memory>

NS_ASSUME_NONNULL_BEGIN
namespace bugsnag {
class PersistentDeviceID: public PhasedStartup {
public:
    PersistentDeviceID() = delete;
    PersistentDeviceID(std::shared_ptr<Persistence> persistence) noexcept
    : persistence_(persistence)
    {}

    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *) noexcept {};
    void preStartSetup() noexcept;
    void start() noexcept {}

    NSString *external() noexcept { return externalDeviceID_; };

    // Not used by bugsnag-cocoa-performance
    NSString *unittest_internal() noexcept { return internalDeviceID_; };

private:
    std::shared_ptr<Persistence> persistence_;
    NSString *externalDeviceID_{@""};
    NSString *internalDeviceID_{@""};
    NSString *persistenceDir_{nil};

    NSString *getFilePath();
    NSError *load();
    NSError *save();
};
}
NS_ASSUME_NONNULL_END
