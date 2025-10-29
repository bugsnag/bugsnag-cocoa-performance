//
//  WorkerTasksBuilder.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "../Core/Worker/AsyncToSyncTask.h"
#import "../Core/SpanStore/SpanStore.h"
#import "../Core/SpanProcessingPipeline/SpanProcessingPipeline.h"
#import "../PluginSupport/PluginManager/BSGPluginManager.h"
#import "../Upload/UploadHandler/UploadHandler.h"

#import <vector>
#import <memory>

namespace bugsnag {
class WorkerTasksBuilder {
public:
    WorkerTasksBuilder(std::shared_ptr<SpanStore> spanStore,
                       std::shared_ptr<UploadHandler> uploadHandler,
                       std::shared_ptr<SpanProcessingPipeline> pipeline,
                       BSGPluginManager *pluginManager) noexcept
    : spanStore_(spanStore)
    , uploadHandler_(uploadHandler)
    , pipeline_(pipeline)
    , pluginManager_(pluginManager) {};
    
    ~WorkerTasksBuilder() {};
    
    std::vector<std::shared_ptr<AsyncToSyncTask>> buildInitialTasks() noexcept;
    std::vector<std::shared_ptr<AsyncToSyncTask>> buildRecurringTasks() noexcept;
private:
    
    std::shared_ptr<SpanStore> spanStore_;
    std::shared_ptr<UploadHandler> uploadHandler_;
    std::shared_ptr<SpanProcessingPipeline> pipeline_;
    BSGPluginManager *pluginManager_;
    
    std::shared_ptr<AsyncToSyncTask> buildStartPluginsTask() noexcept;
    
    std::shared_ptr<AsyncToSyncTask> buildGetPValueTask() noexcept;
    std::shared_ptr<AsyncToSyncTask> buildSendCurrentBatchTask() noexcept;
    std::shared_ptr<AsyncToSyncTask> buildSendRetriesTask() noexcept;
    std::shared_ptr<AsyncToSyncTask> buildSweepStoreTask() noexcept;
};
}
