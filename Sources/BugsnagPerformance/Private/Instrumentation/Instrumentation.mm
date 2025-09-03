//
//  Instrumentation.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 24.04.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "Instrumentation.h"

#import "ViewLoadInstrumentation/SpanFactory/ViewLoadSpanFactoryImpl.h"
#import "ViewLoadInstrumentation/System/ViewLoadInstrumentationSystemUtilsImpl.h"
#import "ViewLoadInstrumentation/System/ViewLoadSwizzlingHandlerImpl.h"
#import "ViewLoadInstrumentation/State/ViewLoadInstrumentationStateRepositoryImpl.h"
#import "ViewLoadInstrumentation/Lifecycle/ViewLoadLifecycleHandlerImpl.h"
#import "ViewLoadInstrumentation/Lifecycle/ViewLoadEarlyPhaseHandlerImpl.h"
#import "NetworkInstrumentation/State/NetworkInstrumentationStateRepositoryImpl.h"
#import "NetworkInstrumentation/System/BSGURLSessionPerformanceDelegate.h"
#import "NetworkInstrumentation/System/NetworkInstrumentationSystemUtilsImpl.h"
#import "NetworkInstrumentation/System/NetworkSwizzlingHandlerImpl.h"
#import "NetworkInstrumentation/Lifecycle/NetworkEarlyPhaseHandlerImpl.h"
#import "NetworkInstrumentation/Lifecycle/NetworkLifecycleHandlerImpl.h"
#import "NetworkInstrumentation/SpanFactory/NetworkSpanFactoryImpl.h"

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

#pragma mark - Factory functions

std::shared_ptr<ViewLoadInstrumentation> createViewLoadInstrumentation(std::shared_ptr<Tracer> tracer,
                                                                       std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) {
    auto systemUtils = std::make_shared<ViewLoadInstrumentationSystemUtilsImpl>();
    auto swizzlingHandler = std::make_shared<ViewLoadSwizzlingHandlerImpl>();
    auto spanFactory = std::make_shared<ViewLoadSpanFactoryImpl>(tracer, spanAttributesProvider);
    auto repository = std::make_shared<ViewLoadInstrumentationStateRepositoryImpl>();
    auto earlyPhaseHandler = std::make_shared<ViewLoadEarlyPhaseHandlerImpl>(tracer);
    auto lifecycleHandler = std::make_shared<ViewLoadLifecycleHandlerImpl>(earlyPhaseHandler,
                                                                           spanAttributesProvider,
                                                                           spanFactory,
                                                                           repository,
                                                                           [BugsnagPerformanceCrossTalkAPI sharedInstance]);
    
    return std::make_shared<ViewLoadInstrumentation>(systemUtils, swizzlingHandler, lifecycleHandler);
}

std::shared_ptr<NetworkInstrumentation> createNetworkInstrumentation(std::shared_ptr<Tracer> tracer,
                                                                     std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                                                                     std::shared_ptr<NetworkHeaderInjector> networkHeaderInjector) {
    auto repository = std::make_shared<NetworkInstrumentationStateRepositoryImpl>();
    auto systemUtils = std::make_shared<NetworkInstrumentationSystemUtilsImpl>();
    auto swizzlingHandler = std::make_shared<NetworkSwizzlingHandlerImpl>();
    auto earlyPhaseHandler = std::make_shared<NetworkEarlyPhaseHandlerImpl>(tracer, spanAttributesProvider);
    auto spanFactory = std::make_shared<NetworkSpanFactoryImpl>(tracer, spanAttributesProvider);
    auto lifecycleHandler = std::make_shared<NetworkLifecycleHandlerImpl>(tracer,
                                                                          spanAttributesProvider,
                                                                          spanFactory,
                                                                          earlyPhaseHandler,
                                                                          systemUtils,
                                                                          repository,
                                                                          networkHeaderInjector);
    auto delegate = [[BSGURLSessionPerformanceDelegate alloc] initWithLifecycleHandler:lifecycleHandler];
    return std::make_shared<NetworkInstrumentation>(systemUtils,
                                                    swizzlingHandler,
                                                    lifecycleHandler,
                                                    delegate);
}
