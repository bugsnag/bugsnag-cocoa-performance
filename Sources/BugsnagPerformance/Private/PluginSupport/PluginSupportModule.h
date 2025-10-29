//
//  PluginSupportModule.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "../Core/Module.h"
#import "SpanControl/BSGCompositeSpanControlProvider.h"
#import "PluginManager/BSGPluginManager.h"

#import <memory>

namespace bugsnag {
class PluginSupportModule: public Module {
public:
    PluginSupportModule(BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> *spanStartCallbacks,
                        BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> *spanEndCallbacks) noexcept
    : spanStartCallbacks_(spanStartCallbacks)
    , spanEndCallbacks_(spanEndCallbacks) {};
    
    ~PluginSupportModule() {};
    
    void earlyConfigure(BSGEarlyConfiguration *) noexcept;
    void earlySetup() noexcept;
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept;
    void start() noexcept;
    
    void setUp() noexcept;
    
    void installPlugins(NSArray<id<BugsnagPerformancePlugin>> *plugins) noexcept {
        [pluginManager_ installPlugins:plugins];
    }
    
    BSGCompositeSpanControlProvider *getSpanControlProvider() noexcept { return spanControlProvider_; }
    BSGPluginManager *getPluginManager() noexcept { return pluginManager_; }
    
private:
    // Dependencies
    BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> *spanStartCallbacks_;
    BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> *spanEndCallbacks_;
    
    // Components
    BSGCompositeSpanControlProvider *spanControlProvider_;
    BSGPluginManager *pluginManager_;

};
}
