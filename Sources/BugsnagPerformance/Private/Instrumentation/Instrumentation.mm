//
//  Instrumentation.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 24.04.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "Instrumentation.h"

using namespace bugsnag;

void Instrumentation::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    appStartupInstrumentation_->earlyConfigure(config);
    viewLoadInstrumentation_->earlyConfigure(config);
    networkInstrumentation_->earlyConfigure(config);
}

void Instrumentation::earlySetup() noexcept {
    appStartupInstrumentation_->earlySetup();
    viewLoadInstrumentation_->earlySetup();
    networkInstrumentation_->earlySetup();
}

void Instrumentation::configure(BugsnagPerformanceConfiguration *config) noexcept {
    appStartupInstrumentation_->configure(config);
    viewLoadInstrumentation_->configure(config);
    networkInstrumentation_->configure(config);
}

void Instrumentation::preStartSetup() noexcept {
    appStartupInstrumentation_->preStartSetup();
    viewLoadInstrumentation_->preStartSetup();
    networkInstrumentation_->preStartSetup();
}

void Instrumentation::start() noexcept {
    appStartupInstrumentation_->start();
    viewLoadInstrumentation_->start();
    networkInstrumentation_->start();
}

void Instrumentation::abortAppStartupSpans() noexcept {
    appStartupInstrumentation_->abortAllSpans();
}

NSMutableArray<BugsnagPerformanceSpanCondition *> *Instrumentation::loadingIndicatorWasAdded(UIView *loadingViewIndicator) noexcept {
    return viewLoadInstrumentation_->loadingIndicatorWasAdded(loadingViewIndicator);
}
