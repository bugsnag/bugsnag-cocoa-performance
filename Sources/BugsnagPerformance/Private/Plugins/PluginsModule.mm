//
//  PluginsModule.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "PluginsModule.h"

using namespace bugsnag;

void PluginsModule::setUp() noexcept {
    appStartTypePlugin_ = [BugsnagPerformanceAppStartTypePlugin new];
    [appStartTypePlugin_ setGetAppStartInstrumentationStateCallback:^AppStartupInstrumentationStateSnapshot * _Nullable {
        return instrumentation_->getAppStartInstrumentationStateSnapshot();
    }];
}
