//
//  CoreModule.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "Module.h"
#import "AppLifecycleListener.h"

#import "Attributes/ResourceAttributes.h"
#import "Sampler/PersistentState.h"
#import "Sampler/Sampler.h"
#import "SpanFactory/AppStartup/AppStartupSpanFactoryImpl.h"
#import "SpanFactory/ViewLoad/ViewLoadSpanFactoryImpl.h"
#import "SpanFactory/Network/NetworkSpanFactoryImpl.h"
#import "SpanFactory/Plain/PlainSpanFactoryImpl.h"
#import "SpanStack/SpanStackingHandler.h"
#import "SpanStore/SpanStoreImpl.h"
#import "SpanLifecycle/SpanLifecycleHandlerImpl.h"
#import "NetworkSpanReporter/NetworkSpanReporterImpl.h"
#import "Worker/Worker.h"
#import "BSGPrioritizedStore.h"
#import "SpanConditions/ConditionTimeoutExecutor.h"
#import "SpanProcessingPipeline/Batch.h"
#import "SpanProcessingPipeline/SpanProcessingPipelineImpl.h"

#import "../Utils/Persistence.h"
#import "../Utils/PersistentDeviceID.h"
#import "../Metrics/FrameMetrics/FrameMetricsSnapshot.h"
#import "../Instrumentation/AppStartupInstrumentation/State/AppStartupInstrumentationStateSnapshot.h"

#import <vector>

namespace bugsnag {
class CoreModule: public Module, public AppLifecycleListener {
public:
    CoreModule(AppStateTracker *appStateTracker,
               std::shared_ptr<Reachability> reachability,
               std::shared_ptr<Persistence> persistence,
               std::shared_ptr<PersistentDeviceID> deviceID,
               BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> *spanStartCallbacks) noexcept
    : appStateTracker_(appStateTracker)
    , reachability_(reachability)
    , persistence_(persistence)
    , deviceID_(deviceID)
    , spanStartCallbacks_(spanStartCallbacks) {};
    
    ~CoreModule();
    
    void earlyConfigure(BSGEarlyConfiguration *config) noexcept;
    void earlySetup() noexcept;
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept;
    void start() noexcept;
    
    void setUp() noexcept;
    void onAppFinishedLaunching() noexcept {}
    void onAppEnteredBackground() noexcept;
    void onAppEnteredForeground() noexcept;
    
    void initializeComponentsCallbacks(GetCurrentFrameMetricsSnapshot getCurrentSnapshot,
                                       GetAppStartupStateSnapshot getAppStartupStateSnapshot,
                                       HandleStringTask onViewLoadSpanStarted,
                                       double spanProcessingDelay) noexcept {
        spanLifecycleHandler_->initialize(getCurrentSnapshot);
        plainSpanFactory_->setup(createPlainSpanFactoryCallbacks());
        viewLoadSpanFactory_->setup(createViewLoadSpanFactoryCallbacks(onViewLoadSpanStarted, getAppStartupStateSnapshot));
        pipeline_->setMainFlowDelay(spanProcessingDelay);
    }
    
    void initializeWorkerTasks(std::vector<std::shared_ptr<AsyncToSyncTask>> initialTasks,
                               std::vector<std::shared_ptr<AsyncToSyncTask>> recurringTasks) {
        for (const auto &task : initialTasks) {
            [worker_ addInitialTask:task];
        }
        for (const auto &task : recurringTasks) {
            [worker_ addRecurringTask:task];
        }
    }
    
    void initializePipelineSteps(std::vector<std::shared_ptr<SpanProcessingPipelineStep>> preprocessSteps,
                                 std::vector<std::shared_ptr<SpanProcessingPipelineStep>> mainFlowSteps) {
        for (const auto &step : preprocessSteps) {
            pipeline_->addPreprocessStep(step);
        }
        for (const auto &step : mainFlowSteps) {
            pipeline_->addMainFlowStep(step);
        }
    }
    
    // Tasks
    
    UpdateProbabilityTask getUpdateProbabilityTask() noexcept;
    UpdateConnectivityTask getUpdateConnectivityTask() noexcept;
    
    // Components access
    
    std::shared_ptr<Batch> getBatch() noexcept { return batch_; }
    std::shared_ptr<PlainSpanFactory> getPlainSpanFactory() noexcept { return plainSpanFactory_; }
    std::shared_ptr<AppStartupSpanFactory> getAppStartupSpanFactory() noexcept { return appStartupSpanFactory_; }
    std::shared_ptr<ViewLoadSpanFactory> getViewLoadSpanFactory() noexcept { return viewLoadSpanFactory_; }
    std::shared_ptr<NetworkSpanFactory> getNetworkSpanFactory() noexcept { return networkSpanFactory_; }
    std::shared_ptr<SpanAttributesProvider> getSpanAttributesProvider() noexcept { return spanAttributesProvider_; }
    std::shared_ptr<SpanStackingHandler> getSpanStackingHandler() noexcept { return spanStackingHandler_; }
    std::shared_ptr<SpanStore> getSpanStore() noexcept { return spanStore_; }
    std::shared_ptr<Sampler> getSampler() noexcept { return sampler_; }
    std::shared_ptr<ConditionTimeoutExecutor> getConditionTimeoutExecutor() noexcept { return conditionTimeoutExecutor_; }
    std::shared_ptr<SpanLifecycleHandler> getSpanLifecycleHandler() noexcept { return spanLifecycleHandler_; }
    std::shared_ptr<ResourceAttributes> getResourceAttributes() noexcept { return resourceAttributes_; }
    std::shared_ptr<NetworkSpanReporter> getNetworkSpanReporter() noexcept { return networkSpanReporter_; }
    std::shared_ptr<SpanProcessingPipeline> getSpanProcessingPipeline() noexcept { return pipeline_; }
    
private:
    
    bool isStarted_{false};
    BugsnagPerformanceConfiguration *configuration_;
    
    NSTimer *workerTimer_{nil};
    
    // Dependencies
    AppStateTracker *appStateTracker_;
    std::shared_ptr<Reachability> reachability_;
    std::shared_ptr<Persistence> persistence_;
    std::shared_ptr<PersistentDeviceID> deviceID_;
    std::function<AppStartupInstrumentationStateSnapshot *()> getAppStartupInstrumentationState_{ [](){ return nil; } };
    BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> *spanStartCallbacks_;
    
    // Components
    std::shared_ptr<Batch> batch_;
    std::shared_ptr<PersistentState> persistentState_;
    std::shared_ptr<PlainSpanFactoryImpl> plainSpanFactory_;
    std::shared_ptr<AppStartupSpanFactoryImpl> appStartupSpanFactory_;
    std::shared_ptr<ViewLoadSpanFactoryImpl> viewLoadSpanFactory_;
    std::shared_ptr<NetworkSpanFactoryImpl> networkSpanFactory_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    std::shared_ptr<SpanStackingHandler> spanStackingHandler_;
    std::shared_ptr<SpanStoreImpl> spanStore_;
    std::shared_ptr<Sampler> sampler_;
    std::shared_ptr<ConditionTimeoutExecutor> conditionTimeoutExecutor_;
    std::shared_ptr<SpanLifecycleHandlerImpl> spanLifecycleHandler_;
    std::shared_ptr<ResourceAttributes> resourceAttributes_;
    std::shared_ptr<NetworkSpanReporterImpl> networkSpanReporter_;
    std::shared_ptr<SpanProcessingPipelineImpl> pipeline_;
    Worker *worker_;
    
    PlainSpanFactoryCallbacks *createPlainSpanFactoryCallbacks() noexcept;
    ViewLoadSpanFactoryCallbacks *createViewLoadSpanFactoryCallbacks(HandleStringTask onViewLoadSpanStartedTask,
                                                                     GetAppStartupStateSnapshot getAppStartupStateSnapshot) noexcept;
};
}
