//
//  CrossTalkAPIModule.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "CrossTalkAPIModule.h"

using namespace bugsnag;

#pragma mark PhasedStartup

void
CrossTalkAPIModule::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    [[BugsnagPerformanceCrossTalkAPI sharedInstance] earlyConfigure:config];
}

void
CrossTalkAPIModule::earlySetup() noexcept {
    [[BugsnagPerformanceCrossTalkAPI sharedInstance] earlySetup];
}

void
CrossTalkAPIModule::configure(BugsnagPerformanceConfiguration *config) noexcept {
    [[BugsnagPerformanceCrossTalkAPI sharedInstance] configure:config];
}

void
CrossTalkAPIModule::preStartSetup() noexcept {
    [[BugsnagPerformanceCrossTalkAPI sharedInstance] preStartSetup];
}

void
CrossTalkAPIModule::start() noexcept {
    [[BugsnagPerformanceCrossTalkAPI sharedInstance] start];
}

#pragma mark Module

void
CrossTalkAPIModule::setUp() noexcept {
    [BugsnagPerformanceCrossTalkAPI initializeWithSpanStackingHandler:spanStackingHandler_
                                                          spanFactory:spanFactory_];
}
