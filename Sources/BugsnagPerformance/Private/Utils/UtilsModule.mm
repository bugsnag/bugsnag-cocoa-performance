//
//  UtilsModule.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "UtilsModule.h"

using namespace bugsnag;

static NSString *getPersistenceDir() {
    // Persistent data in bugsnag-performance can handle files disappearing, so put it in the caches dir.
    return NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
}

#pragma mark PhasedStartup

void
UtilsModule::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    persistence_->earlyConfigure(config);
    deviceID_->earlyConfigure(config);
}

void
UtilsModule::earlySetup() noexcept {
    persistence_->earlySetup();
    deviceID_->earlySetup();
}

void
UtilsModule::configure(BugsnagPerformanceConfiguration *config) noexcept {
    persistence_->configure(config);
    deviceID_->configure(config);
}

void
UtilsModule::preStartSetup() noexcept {
    persistence_->preStartSetup();
    deviceID_->preStartSetup();
}

void
UtilsModule::start() noexcept {
    persistence_->start();
    deviceID_->start();
}

#pragma mark Module

void
UtilsModule::setUp() noexcept {
    appStateTracker_ = [[AppStateTracker alloc] init];
    reachability_ = std::make_shared<Reachability>();
    persistence_ = std::make_shared<Persistence>(getPersistenceDir());
    deviceID_ = std::make_shared<PersistentDeviceID>(persistence_);
}

#pragma mark Tasks

ModuleTask
UtilsModule::getClearPersistentDataTask() noexcept {
    __block auto blockThis = this;
    return ^{
        if (blockThis->persistence_ == nullptr) {
            return;
        }
        blockThis->persistence_->clearPerformanceData();
    };
}
