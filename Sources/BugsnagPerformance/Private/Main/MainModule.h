//
//  MainModule.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "WorkerTasksBuilder.h"
#import "../Core/Module.h"
#import "../Core/AppLifecycleListener.h"
#import "../Core/CoreModule.h"
#import "../CrossTalkAPI/CrossTalkAPIModule.h"
#import "../Instrumentation/InstrumentationModule.h"
#import "../Utils/UtilsModule.h"
#import "../Metrics/MetricsModule.h"
#import "../Plugins/PluginsModule.h"
#import "../PluginSupport/PluginSupportModule.h"
#import "../Upload/UploadModule.h"

#import <memory>

namespace bugsnag {
class MainModule: public Module, public AppLifecycleListener {
public:
    MainModule() {};
    
    ~MainModule() {};
    
    void earlyConfigure(BSGEarlyConfiguration *config) noexcept;
    void earlySetup() noexcept;
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept;
    void start() noexcept;
    
    void setUp() noexcept;
    
    void onAppFinishedLaunching() noexcept;
    void onAppEnteredBackground() noexcept;
    void onAppEnteredForeground() noexcept;
    
    std::shared_ptr<CoreModule> getCoreModule() noexcept { return coreModule_; }
    std::shared_ptr<CrossTalkAPIModule> getCrossTalkAPIModule() noexcept { return crossTalkAPIModule_; }
    std::shared_ptr<UtilsModule> getUtilsModule() noexcept { return utilsModule_; }
    std::shared_ptr<InstrumentationModule> getInstrumentationModule() noexcept { return instrumentationModule_; }
    std::shared_ptr<MetricsModule> getMetricsModule() noexcept { return metricsModule_; }
    std::shared_ptr<PluginsModule> getPluginsModule() noexcept { return pluginsModule_; }
    std::shared_ptr<PluginSupportModule> getPluginSupportModule() noexcept { return pluginSupportModule_; }
    std::shared_ptr<UploadModule> getUploadModule() noexcept { return uploadModule_; }
    
private:
    // Components
    std::shared_ptr<CoreModule> coreModule_;
    std::shared_ptr<CrossTalkAPIModule> crossTalkAPIModule_;
    std::shared_ptr<UtilsModule> utilsModule_;
    std::shared_ptr<InstrumentationModule> instrumentationModule_;
    std::shared_ptr<MetricsModule> metricsModule_;
    std::shared_ptr<PluginsModule> pluginsModule_;
    std::shared_ptr<PluginSupportModule> pluginSupportModule_;
    std::shared_ptr<UploadModule> uploadModule_;
    std::shared_ptr<WorkerTasksBuilder> workerTasksBuilder_;
    
    void initializeModules() noexcept;
    std::vector<std::shared_ptr<AsyncToSyncTask>> buildInitialTasks() noexcept;
    std::vector<std::shared_ptr<AsyncToSyncTask>> buildRecurringTasks() noexcept;
};
}
