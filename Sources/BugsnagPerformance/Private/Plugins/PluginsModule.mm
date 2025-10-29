//
//  PluginsModule.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "PluginsModule.h"

using namespace bugsnag;

#pragma mark Module

void PluginsModule::setUp() noexcept {
    appStartTypePlugin_ = [BugsnagPerformanceAppStartTypePlugin new];
    [appStartTypePlugin_ setGetAppStartInstrumentationStateCallback:^AppStartupInstrumentationStateSnapshot * _Nullable {
        return instrumentation_->getAppStartInstrumentationStateSnapshot();
    }];
}

#pragma mark Tasks

GetPluginsTask
PluginsModule::getDefaultPluginsTask() {
    return ^NSArray<id<BugsnagPerformancePlugin>> *(){
        NSMutableArray<id<BugsnagPerformancePlugin>> *defaultPlugins = [NSMutableArray array];
        if (appStartTypePlugin_ != nil) {
            [defaultPlugins addObject:appStartTypePlugin_];
        }
        return defaultPlugins;
    };
    
}
