//
//  MainModule.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "MainModule.h"

using namespace bugsnag;

#pragma mark PhasedStartup

void
MainModule::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    // Do MetricsModule first so that any early spans will always have a bounding sample
    metricsModule_->earlyConfigure(config);
    utilsModule_->earlyConfigure(config);
    coreModule_->earlyConfigure(config);
    instrumentationModule_->earlyConfigure(config);
    uploadModule_->earlyConfigure(config);
    pluginSupportModule_->earlyConfigure(config);
    pluginsModule_->earlyConfigure(config);
    crossTalkAPIModule_->earlyConfigure(config);
    
    // Configure these here because notifications may arrive
    // before Bugsnag is started.
    __block auto blockThis = this;
    utilsModule_->getAppStateTracker().onAppFinishedLaunching = ^{
        blockThis->onAppFinishedLaunching();
    };

    utilsModule_->getAppStateTracker().onTransitionToBackground = ^{
        blockThis->onAppEnteredBackground();
    };

    utilsModule_->getAppStateTracker().onTransitionToForeground = ^{
        blockThis->onAppEnteredForeground();
    };
}

void
MainModule::earlySetup() noexcept {
    metricsModule_->earlySetup();
    utilsModule_->earlySetup();
    coreModule_->earlySetup();
    instrumentationModule_->earlySetup();
    uploadModule_->earlySetup();
    pluginSupportModule_->earlySetup();
    pluginsModule_->earlySetup();
    crossTalkAPIModule_->earlySetup();
}

void
MainModule::configure(BugsnagPerformanceConfiguration *config) noexcept {    
    metricsModule_->configure(config);
    utilsModule_->configure(config);
    coreModule_->configure(config);
    instrumentationModule_->configure(config);
    uploadModule_->configure(config);
    pluginSupportModule_->configure(config);
    pluginsModule_->configure(config);
    crossTalkAPIModule_->configure(config);
    
    pluginSupportModule_->installPlugins(pluginsModule_->getDefaultPluginsTask()());
}

void
MainModule::preStartSetup() noexcept {
    metricsModule_->preStartSetup();
    utilsModule_->preStartSetup();
    coreModule_->preStartSetup();
    instrumentationModule_->preStartSetup();
    uploadModule_->preStartSetup();
    pluginSupportModule_->preStartSetup();
    pluginsModule_->preStartSetup();
    crossTalkAPIModule_->preStartSetup();
}

void
MainModule::start() noexcept {
    metricsModule_->start();
    utilsModule_->start();
    coreModule_->start();
    instrumentationModule_->start();
    uploadModule_->start();
    pluginSupportModule_->start();
    pluginsModule_->start();
    crossTalkAPIModule_->start();
}

#pragma mark Module

void
MainModule::setUp() noexcept {
    initializeModules();
}

#pragma mark AppLifecycleListener

void
MainModule::onAppFinishedLaunching() noexcept {
    coreModule_->onAppFinishedLaunching();
    instrumentationModule_->onAppFinishedLaunching();
    metricsModule_->onAppFinishedLaunching();
}

void
MainModule::onAppEnteredBackground() noexcept {
    coreModule_->onAppEnteredBackground();
    instrumentationModule_->onAppEnteredBackground();
    metricsModule_->onAppEnteredBackground();
}

void
MainModule::onAppEnteredForeground() noexcept {
    coreModule_->onAppEnteredForeground();
    instrumentationModule_->onAppEnteredForeground();
    metricsModule_->onAppEnteredForeground();
}

#pragma mark Private

void
MainModule::initializeModules() noexcept {
    spanStartCallbacks_ = [BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> new];
    spanEndCallbacks_ = [BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> new];
    utilsModule_ = std::make_shared<UtilsModule>();
    utilsModule_->setUp();
    coreModule_ = std::make_shared<CoreModule>(utilsModule_->getAppStateTracker(),
                                               utilsModule_->getReachability(),
                                               utilsModule_->getPersistence(),
                                               utilsModule_->getDeviceID(),
                                               spanStartCallbacks_);
    coreModule_->setUp();
    instrumentationModule_ = std::make_shared<InstrumentationModule>(coreModule_->getAppStartupSpanFactory(),
                                                                     coreModule_->getViewLoadSpanFactory(),
                                                                     coreModule_->getNetworkSpanFactory(),
                                                                     coreModule_->getSpanAttributesProvider(),
                                                                     coreModule_->getSpanStackingHandler(),
                                                                     coreModule_->getSampler());
    instrumentationModule_->setUp();
    metricsModule_ = std::make_shared<MetricsModule>();
    metricsModule_->setUp();
    
    crossTalkAPIModule_ = std::make_shared<CrossTalkAPIModule>(coreModule_->getPlainSpanFactory(),
                                                               coreModule_->getSpanStackingHandler());
    crossTalkAPIModule_->setUp();
    
    pluginsModule_ = std::make_shared<PluginsModule>(instrumentationModule_->getInstrumentation());
    pluginsModule_->setUp();
    
    pluginSupportModule_ = std::make_shared<PluginSupportModule>(spanStartCallbacks_,
                                                                 spanEndCallbacks_);
    pluginSupportModule_->setUp();
    
    uploadModule_ = std::make_shared<UploadModule>(utilsModule_->getPersistence(),
                                                   coreModule_->getResourceAttributes());
    uploadModule_->setUp();
    
    utilsModule_->initializeComponentsCallbacks(coreModule_->getUpdateConnectivityTask());
    uploadModule_->initializeComponentsCallbacks(utilsModule_->getClearPersistentDataTask(),
                                                 coreModule_->getUpdateProbabilityTask());
    coreModule_->initializeComponentsCallbacks(metricsModule_->getCurrentFrameMetricsSnapshotTask(),
                                               instrumentationModule_->getAppStartupStateSnapshotTask(),
                                               instrumentationModule_->getHandleViewLoadSpanStartedTask(),
                                               metricsModule_->getSamplerInterval());
    
    pipelineStepsBuilder_ = std::make_shared<PipelineStepsBuilder>(metricsModule_->getSystemInfoSampler(),
                                                                   coreModule_->getSpanAttributesProvider(),
                                                                   coreModule_->getPlainSpanFactory(),
                                                                   coreModule_->getSampler(),
                                                                   spanEndCallbacks_);
    coreModule_->initializePipelineSteps(pipelineStepsBuilder_->buildPreprocessSteps(),
                                         pipelineStepsBuilder_->buildMainFlowSteps());
    
    workerTasksBuilder_ = std::make_shared<WorkerTasksBuilder>(coreModule_->getSpanStore(),
                                                               uploadModule_->getUploadHandler(),
                                                               coreModule_->getSpanProcessingPipeline(),
                                                               pluginSupportModule_->getPluginManager());
    coreModule_->initializeWorkerTasks(workerTasksBuilder_->buildInitialTasks(),
                                       workerTasksBuilder_->buildRecurringTasks());
}
