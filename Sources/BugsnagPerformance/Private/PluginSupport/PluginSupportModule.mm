//
//  PluginSupportModule.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "PluginSupportModule.h"

using namespace bugsnag;

#pragma mark PhasedStartup

void
PluginSupportModule::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    [pluginManager_ earlyConfigure:config];
}

void
PluginSupportModule::earlySetup() noexcept {
    [pluginManager_ earlySetup];
}

void
PluginSupportModule::configure(BugsnagPerformanceConfiguration *config) noexcept {
    [pluginManager_ configure:config];
}

void
PluginSupportModule::preStartSetup() noexcept {
    [pluginManager_ preStartSetup];
}

void
PluginSupportModule::start() noexcept {
    [pluginManager_ start];
}

#pragma mark Module

void
PluginSupportModule::setUp() noexcept {
    spanControlProvider_ = [BSGCompositeSpanControlProvider new];
    pluginManager_ = [[BSGPluginManager alloc] initWithSpanControlProvider:spanControlProvider_];
}
