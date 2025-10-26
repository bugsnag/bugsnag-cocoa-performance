//
//  InstrumentationModule.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "InstrumentationModule.h"

// App Startup Instrumentation
#import "AppStartupInstrumentation/System/AppStartupInstrumentationSystemUtilsImpl.h"
#import "AppStartupInstrumentation/Lifecycle/AppStartupLifecycleHandlerImpl.h"

// View Load Instrumentation
#import "ViewLoadInstrumentation/System/ViewLoadInstrumentationSystemUtilsImpl.h"
#import "ViewLoadInstrumentation/System/ViewLoadSwizzlingHandlerImpl.h"
#import "ViewLoadInstrumentation/Lifecycle/EarlyPhase/ViewLoadEarlyPhaseHandlerImpl.h"
#import "ViewLoadInstrumentation/Lifecycle/LoadingIndicators/ViewLoadLoadingIndicatorsHandlerImpl.h"
#import "ViewLoadInstrumentation/Lifecycle/ViewLoadLifecycleHandlerImpl.h"

// Network Instrumentation
#import "NetworkInstrumentation/State/NetworkInstrumentationStateRepositoryImpl.h"
#import "NetworkInstrumentation/System/NetworkInstrumentationSystemUtilsImpl.h"
#import "NetworkInstrumentation/System/NetworkSwizzlingHandlerImpl.h"
#import "NetworkInstrumentation/Lifecycle/NetworkEarlyPhaseHandlerImpl.h"
#import "NetworkInstrumentation/Lifecycle/NetworkLifecycleHandlerImpl.h"
#import "NetworkInstrumentation/System/BSGURLSessionPerformanceDelegate.h"

// CrossTalk API
#import "../CrossTalkAPI/BugsnagPerformanceCrossTalkAPI.h"

using namespace bugsnag;

#pragma mark PhasedStartup

void
InstrumentationModule::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    networkHeaderInjector_->earlyConfigure(config);
    appStartupInstrumentation_->earlyConfigure(config);
    viewLoadInstrumentation_->earlyConfigure(config);
    networkInstrumentation_->earlyConfigure(config);
    instrumentation_->earlyConfigure(config);
    [urlSessionDelegate_ earlyConfigure:config];
}

void
InstrumentationModule::earlySetup() noexcept {
    [urlSessionDelegate_ earlySetup];
    networkHeaderInjector_->earlySetup();
    appStartupInstrumentation_->earlySetup();
    viewLoadInstrumentation_->earlySetup();
    networkInstrumentation_->earlySetup();
    instrumentation_->earlySetup();
}

void
InstrumentationModule::configure(BugsnagPerformanceConfiguration *config) noexcept {
    [urlSessionDelegate_ configure:config];
    networkHeaderInjector_->configure(config);
    appStartupInstrumentation_->configure(config);
    viewLoadInstrumentation_->configure(config);
    networkInstrumentation_->configure(config);
    instrumentation_->configure(config);
}

void
InstrumentationModule::preStartSetup() noexcept {
    [urlSessionDelegate_ preStartSetup];
    networkHeaderInjector_->preStartSetup();
    appStartupInstrumentation_->preStartSetup();
    viewLoadInstrumentation_->preStartSetup();
    networkInstrumentation_->preStartSetup();
    instrumentation_->preStartSetup();
}

void
InstrumentationModule::start() noexcept {
    [urlSessionDelegate_ start];
    networkHeaderInjector_->start();
    instrumentation_->start();
    appStartupInstrumentation_->start();
    viewLoadInstrumentation_->start();
    networkInstrumentation_->start();
}

#pragma mark Module

void
InstrumentationModule::setUp() noexcept {
    networkHeaderInjector_ = std::make_shared<NetworkHeaderInjector>(spanAttributesProvider_, spanStackingHandler_, sampler_);
    appStartupInstrumentation_ = createAppStartupInstrumentation(appStartupSpanFactory_,
                                                                 spanAttributesProvider_);
    viewLoadInstrumentation_ = createViewLoadInstrumentation(viewLoadSpanFactory_,
                                                             spanAttributesProvider_);
    networkInstrumentation_ = createNetworkInstrumentation(networkSpanFactory_,
                                                           spanAttributesProvider_,
                                                           networkHeaderInjector_);
    instrumentation_ = std::make_shared<Instrumentation>(appStartupInstrumentation_,
                                                         viewLoadInstrumentation_,
                                                         networkInstrumentation_);
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

#pragma mark Private

std::shared_ptr<AppStartupInstrumentation>
InstrumentationModule::createAppStartupInstrumentation(std::shared_ptr<AppStartupSpanFactory> spanFactory,
                                                                           std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) {
    auto systemUtils = std::make_shared<AppStartupInstrumentationSystemUtilsImpl>();
    auto lifecycleHandler = std::make_shared<AppStartupLifecycleHandlerImpl>(spanFactory,
                                                                             spanAttributesProvider,
                                                                             systemUtils,
                                                                             [BugsnagPerformanceCrossTalkAPI sharedInstance]);
    
    return std::make_shared<AppStartupInstrumentation>(lifecycleHandler, systemUtils);
}

std::shared_ptr<ViewLoadInstrumentation>
InstrumentationModule::createViewLoadInstrumentation(std::shared_ptr<ViewLoadSpanFactory> spanFactory,
                                                                       std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) {
    auto systemUtils = std::make_shared<ViewLoadInstrumentationSystemUtilsImpl>();
    auto swizzlingHandler = std::make_shared<ViewLoadSwizzlingHandlerImpl>();
    viewLoadRepository_ = std::make_shared<ViewLoadInstrumentationStateRepositoryImpl>();
    auto earlyPhaseHandler = std::make_shared<ViewLoadEarlyPhaseHandlerImpl>();
    auto loadingIndicatorsHandler = std::make_shared<ViewLoadLoadingIndicatorsHandlerImpl>(viewLoadRepository_,
                                                                                           viewLoadSpanFactory_);
    viewLoadLifecycleHandler_ = std::make_shared<ViewLoadLifecycleHandlerImpl>(earlyPhaseHandler,
                                                                               spanAttributesProvider,
                                                                               spanFactory,
                                                                               viewLoadRepository_,
                                                                               loadingIndicatorsHandler,
                                                                               [BugsnagPerformanceCrossTalkAPI sharedInstance]);
    
    loadingIndicatorsHandler->setCallbacks(createViewLoadLoadingIndicatorsHandlerCallbacks());
    
    return std::make_shared<ViewLoadInstrumentation>(systemUtils, swizzlingHandler, viewLoadLifecycleHandler_);
}

std::shared_ptr<NetworkInstrumentation>
InstrumentationModule::createNetworkInstrumentation(std::shared_ptr<NetworkSpanFactory> spanFactory,
                                                                     std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                                                                     std::shared_ptr<NetworkHeaderInjector> networkHeaderInjector) {
    auto repository = std::make_shared<NetworkInstrumentationStateRepositoryImpl>();
    auto systemUtils = std::make_shared<NetworkInstrumentationSystemUtilsImpl>();
    auto swizzlingHandler = std::make_shared<NetworkSwizzlingHandlerImpl>();
    auto earlyPhaseHandler = std::make_shared<NetworkEarlyPhaseHandlerImpl>(spanAttributesProvider);
    auto lifecycleHandler = std::make_shared<NetworkLifecycleHandlerImpl>(spanAttributesProvider,
                                                                          spanFactory,
                                                                          earlyPhaseHandler,
                                                                          systemUtils,
                                                                          repository,
                                                                          networkHeaderInjector);
    urlSessionDelegate_ = [[BSGURLSessionPerformanceDelegate alloc] initWithLifecycleHandler:lifecycleHandler];
    return std::make_shared<NetworkInstrumentation>(systemUtils,
                                                    swizzlingHandler,
                                                    lifecycleHandler,
                                                    urlSessionDelegate_);
}

ViewLoadLoadingIndicatorsHandlerCallbacks *
InstrumentationModule::createViewLoadLoadingIndicatorsHandlerCallbacks() noexcept {
    __block auto blockThis = this;
    auto callbacks = [ViewLoadLoadingIndicatorsHandlerCallbacks new];
    callbacks.onLoading = ^BugsnagPerformanceSpanCondition * _Nullable(UIViewController * _Nonnull viewController) {
        return blockThis->viewLoadLifecycleHandler_->onLoadingStarted(viewController);
    };
    
    callbacks.getParentContext = ^BugsnagPerformanceSpanContext * _Nullable(UIViewController * _Nonnull viewController) {
        return blockThis->viewLoadRepository_->getInstrumentationState(viewController).overallSpan;
    };
    
    return callbacks;
}
