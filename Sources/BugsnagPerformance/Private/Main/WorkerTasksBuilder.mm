//
//  WorkerTasksBuilder.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "WorkerTasksBuilder.h"

#define buildTask(work) \
    __block auto blockThis = this; \
    auto workBlock = ^(TaskCompletion completion){ \
        work \
    }; \
    return std::make_shared<AsyncToSyncTask>(workBlock)

using namespace bugsnag;

std::vector<std::shared_ptr<AsyncToSyncTask>>
WorkerTasksBuilder::buildInitialTasks() noexcept {
    auto result = std::vector<std::shared_ptr<AsyncToSyncTask>>();
    result.push_back(buildGetInitialPValueTask());
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

#pragma mark Initial Tasks

std::shared_ptr<AsyncToSyncTask>
WorkerTasksBuilder::buildGetInitialPValueTask() noexcept {
    return buildGetPValueTask();
}

std::shared_ptr<AsyncToSyncTask>
WorkerTasksBuilder::buildStartPluginsTask() noexcept {
    buildTask(
        [blockThis->pluginManager_ startPlugins];
        completion(false);
    );
}

std::shared_ptr<AsyncToSyncTask>
WorkerTasksBuilder::buildGetPValueTask() noexcept {
    buildTask(
        blockThis->uploadHandler_->uploadPValueRequest(completion);
    );
}

std::shared_ptr<AsyncToSyncTask>
WorkerTasksBuilder::buildSendCurrentBatchTask() noexcept {
    buildTask(
        blockThis->pipeline_->processPendingSpansIfNeeded();
        auto spans = blockThis->pipeline_->drainSendableSpans();
        if (spans.count == 0) {
            completion(false);
            return;
        }
        blockThis->uploadHandler_->uploadSpans(spans, completion);
    );
}

std::shared_ptr<AsyncToSyncTask>
WorkerTasksBuilder::buildSendRetriesTask() noexcept {
    buildTask(
        blockThis->uploadHandler_->sendRetries(completion);
    );
}

std::shared_ptr<AsyncToSyncTask>
WorkerTasksBuilder::buildSweepStoreTask() noexcept {
    buildTask(
        blockThis->spanStore_->sweep();
        completion(false);
    );
}
