//
//  ResourceAttributes.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 02/11/2022.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#pragma once

#import "PhasedStartup.h"
#import "PersistentDeviceID.h"
#import <memory>

NS_ASSUME_NONNULL_BEGIN
namespace bugsnag {
class ResourceAttributes: public PhasedStartup {
public:
    ResourceAttributes(std::shared_ptr<PersistentDeviceID> deviceID) noexcept
    : deviceID_(deviceID)
    {}

    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *configuration) noexcept;
    void start() noexcept;

    NSDictionary *get() noexcept { return cachedAttributes_; };
    
private:
    std::shared_ptr<PersistentDeviceID> deviceID_;
    NSString *releaseStage_{nil};
    NSString *bundleVersion_{nil};
    NSString *serviceVersion_{nil};
    NSDictionary *cachedAttributes_{nil};
};
}
NS_ASSUME_NONNULL_END
