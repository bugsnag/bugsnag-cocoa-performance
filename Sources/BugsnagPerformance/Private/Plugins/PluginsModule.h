//
//  PluginsModule.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "../Core/Module.h"
#import "../Instrumentation/Instrumentation.h"
#import "AppStart/BugsnagPerformanceAppStartTypePlugin.h"

#import <memory>

namespace bugsnag {
class PluginsModule: public Module {
public:
    PluginsModule(std::shared_ptr<Instrumentation> instrumentation)
    : instrumentation_(instrumentation) {};
    
    ~PluginsModule() {};
    
    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *) noexcept {}
    void preStartSetup() noexcept {}
    void start() noexcept {}
    
    void setUp() noexcept;
    
    BugsnagPerformanceAppStartTypePlugin *getAppStartTypePlugin() noexcept { return appStartTypePlugin_; }
    
private:
    
    // Dependencies
    std::shared_ptr<Instrumentation> instrumentation_;
    
    // Components
    BugsnagPerformanceAppStartTypePlugin *appStartTypePlugin_;
};
}
