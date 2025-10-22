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
    PluginSupportModule() {};
    
    ~PluginSupportModule() {};
    
    void earlyConfigure(BSGEarlyConfiguration *) noexcept;
    void earlySetup() noexcept;
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept;
    void start() noexcept;
    
    void setUp() noexcept;
    
    BSGCompositeSpanControlProvider *getSpanControlProvider() noexcept { return spanControlProvider_; }
    
private:
    
    // Components
    BSGCompositeSpanControlProvider *spanControlProvider_;
    BSGPluginManager *pluginManager_;

};
}
