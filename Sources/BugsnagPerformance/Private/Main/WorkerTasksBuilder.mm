//
//  WorkerTasksBuilder.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "WorkerTasksBuilder.h"

using namespace bugsnag;

std::vector<std::shared_ptr<AsyncToSyncTask>>
WorkerTasksBuilder::buildInitialTasks() noexcept {
    auto result = std::vector<std::shared_ptr<AsyncToSyncTask>>();
    result.push_back(buildGetPValueTask());
    result.push_back(buildStartPluginsTask());
    return result;
}

std::vector<std::shared_ptr<AsyncToSyncTask>>
WorkerTasksBuilder::buildRecurringTasks() noexcept {
    auto result = std::vector<std::shared_ptr<AsyncToSyncTask>>();
    result.push_back(buildGetPValueTask());
    result.push_back(buildSendCurrentBatchTask());
    result.push_back(buildSendRetriesTask());
    result.push_back(buildSweepStoreTask());
    return result;
}

#pragma mark Private

std::shared_ptr<AsyncToSyncTask>
WorkerTasksBuilder::buildGetPValueTask() noexcept {
    __block auto blockThis = this;
    auto work = ^(TaskCompletion completion){
        blockThis->uploadHandler_->uploadPValueRequest(completion);
    };
    return std::make_shared<AsyncToSyncTask>(work);
}

std::shared_ptr<AsyncToSyncTask>
WorkerTasksBuilder::buildStartPluginsTask() noexcept {
    __block auto blockThis = this;
    auto work = ^(TaskCompletion completion){
        [blockThis->pluginManager_ startPlugins];
        completion(false);
    };
    return std::make_shared<AsyncToSyncTask>(work);
}

std::shared_ptr<AsyncToSyncTask>
WorkerTasksBuilder::buildSendCurrentBatchTask() noexcept {
    __block auto blockThis = this;
    auto work = ^(TaskCompletion completion){
        // TODO
        blockThis->uploadHandler_->uploadSpans(@[], completion);
    };
    return std::make_shared<AsyncToSyncTask>(work);
}

std::shared_ptr<AsyncToSyncTask>
WorkerTasksBuilder::buildSendRetriesTask() noexcept {
    __block auto blockThis = this;
    auto work = ^(TaskCompletion completion){
        blockThis->uploadHandler_->sendRetries(completion);
    };
    return std::make_shared<AsyncToSyncTask>(work);
}

std::shared_ptr<AsyncToSyncTask>
WorkerTasksBuilder::buildSweepStoreTask() noexcept {
    __block auto blockThis = this;
    auto work = ^(TaskCompletion completion){
        blockThis->spanStore_->sweep();
        completion(false);
    };
    return std::make_shared<AsyncToSyncTask>(work);
}
