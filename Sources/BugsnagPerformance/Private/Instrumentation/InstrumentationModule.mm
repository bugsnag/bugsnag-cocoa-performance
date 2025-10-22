//
//  InstrumentationModule.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "InstrumentationModule.h"

using namespace bugsnag;

#pragma mark PhasedStartup

void
InstrumentationModule::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    networkHeaderInjector_->earlyConfigure(config);
    instrumentation_->earlyConfigure(config);
}

void
InstrumentationModule::earlySetup() noexcept {
    networkHeaderInjector_->earlySetup();
    instrumentation_->earlySetup();
}

void
InstrumentationModule::configure(BugsnagPerformanceConfiguration *config) noexcept {
    networkHeaderInjector_->configure(config);
    instrumentation_->configure(config);
}

void
InstrumentationModule::preStartSetup() noexcept {
    networkHeaderInjector_->preStartSetup();
    instrumentation_->preStartSetup();
}

void
InstrumentationModule::start() noexcept {
    networkHeaderInjector_->start();
    instrumentation_->start();
}

#pragma mark Module

void
InstrumentationModule::setUp() noexcept {
    networkHeaderInjector_ = std::make_shared<NetworkHeaderInjector>(spanAttributesProvider_, spanStackingHandler_, sampler_);
    
    instrumentation_ = std::make_shared<Instrumentation>(appStartupSpanFactory_,
                                                         viewLoadSpanFactory_,
                                                         networkSpanFactory_,
                                                         spanAttributesProvider_,
                                                         networkHeaderInjector_);
}

#pragma mark Tasks

GetAppStartupStateSnapshot
InstrumentationModule::getAppStartupStateSnapshotTask() noexcept {
    __block auto blockThis = this;
    return ^AppStartupInstrumentationStateSnapshot *{
        if (blockThis->instrumentation_ == nullptr) {
            return nil;
        }
        return blockThis->instrumentation_->getAppStartInstrumentationStateSnapshot();
    };
}

HandleStringTask
InstrumentationModule::getHandleViewLoadSpanStartedTask() noexcept {
    __block auto blockThis = this;
    return ^(NSString *viewName){
        if (blockThis->instrumentation_ == nullptr) {
            return;
        }
        blockThis->instrumentation_->didStartViewLoadSpan(viewName);
    };
}

#pragma mark AppLifecycleListener

void
InstrumentationModule::onAppFinishedLaunching() noexcept {
    instrumentation_->onAppFinishedLaunching();
}

void
InstrumentationModule::onAppEnteredBackground() noexcept {
    instrumentation_->onAppEnteredBackground();
}

void
InstrumentationModule::onAppEnteredForeground() noexcept {
    instrumentation_->onAppEnteredForeground();
}
