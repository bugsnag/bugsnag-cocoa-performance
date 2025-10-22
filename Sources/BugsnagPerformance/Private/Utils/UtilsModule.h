//
//  UtilsModule.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "../Core/Module.h"
#import "AppStateTracker.h"
#import "Reachability.h"
#import "Persistence.h"
#import "PersistentDeviceID.h"

#import <memory>

namespace bugsnag {
class UtilsModule: public Module {
public:
    UtilsModule() {};
    
    ~UtilsModule() {};
    
    void earlyConfigure(BSGEarlyConfiguration *) noexcept;
    void earlySetup() noexcept;
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept;
    void start() noexcept;
    
    void setUp() noexcept;
    void initializeComponentsCallbacks(UpdateConnectivityTask updateConnectivityTask) noexcept {
        reachability_->addCallback(updateConnectivityTask);
    }
    
    // Tasks
    ModuleTask getClearPersistentDataTask() noexcept;
    
    // Components access
    AppStateTracker *getAppStateTracker() noexcept { return appStateTracker_; }
    std::shared_ptr<Reachability> getReachability() noexcept { return reachability_; }
    std::shared_ptr<Persistence> getPersistence() noexcept { return persistence_; }
    std::shared_ptr<PersistentDeviceID> getDeviceID() noexcept { return deviceID_; }
    
private:
    
    // Components
    AppStateTracker *appStateTracker_;
    std::shared_ptr<Reachability> reachability_;
    std::shared_ptr<Persistence> persistence_;
    std::shared_ptr<PersistentDeviceID> deviceID_;
};
}
