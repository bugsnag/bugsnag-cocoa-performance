//
//  BugsnagPerformanceImpl.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 15.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import <BugsnagPerformance/BugsnagPerformanceViewType.h>

#import "BugsnagPerformanceSpan+Private.h"
#import "OtlpUploader.h"
#import "Sampler.h"
#import "Tracer.h"
#import "Worker.h"
#import "Persistence.h"
#import "PersistentState.h"
#import "Reachability.h"

#import <mutex>

namespace bugsnag {
class BugsnagPerformanceImpl {
public:
    BugsnagPerformanceImpl() noexcept;
    
    bool start(BugsnagPerformanceConfiguration *configuration, NSError **error) noexcept;
    
    void reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept {
        tracer_.reportNetworkSpan(task, metrics);
    }

    BugsnagPerformanceSpan *startSpan(NSString *name) {
        return [[BugsnagPerformanceSpan alloc] initWithSpan:
                tracer_.startSpan(name, CFAbsoluteTimeGetCurrent())];
    }

    BugsnagPerformanceSpan *startSpan(NSString *name, NSDate *startTime) {
        return [[BugsnagPerformanceSpan alloc] initWithSpan:
                tracer_.startSpan(name, startTime.timeIntervalSinceReferenceDate)];
    }

    BugsnagPerformanceSpan *startViewLoadSpan(NSString *name, BugsnagPerformanceViewType viewType) {
        return [[BugsnagPerformanceSpan alloc] initWithSpan:
                tracer_.startViewLoadedSpan(viewType, name, CFAbsoluteTimeGetCurrent())];
    }

    BugsnagPerformanceSpan *startViewLoadSpan(NSString *name, BugsnagPerformanceViewType viewType, NSDate *startTime) {
        return [[BugsnagPerformanceSpan alloc] initWithSpan:
                tracer_.startViewLoadedSpan(viewType, name, startTime.timeIntervalSinceReferenceDate)];
    }

    void reportNetworkRequestSpan(NSURLSessionTask * task, NSURLSessionTaskMetrics *metrics) {
        tracer_.reportNetworkSpan(task, metrics);
    }


private:
    bool started_;
    std::mutex mutex_;
    std::shared_ptr<Batch> batch_;
    std::shared_ptr<class Sampler> sampler_;
    Tracer tracer_;
    Worker *worker_;
    std::shared_ptr<Persistence> persistence_;
    std::shared_ptr<PersistentState> persistentState_;
    std::shared_ptr<OtlpUploader> uploader_;
    std::vector<std::unique_ptr<OtlpPackage>> retryQueue_;
    NSDictionary *resourceAttributes_;
    bool shouldPersistState_;

    // Tasks
    NSArray<Task> *buildInitialTasks();
    NSArray<Task> *buildRecurringTasks();
    bool sendCurrentBatchTask();
    bool sendCurrentBatchAndRetriesTask();
    bool sendInitialPValueRequestTask();
    bool maybePersistStateTask();

    // Event reactions
    void onBatchFull() noexcept;
    void onConnectivityChanged(Reachability::Connectivity connectivity) noexcept;
    void onProbabilityChanged(double newProbability) noexcept;
    void onPersistentStateChanged() noexcept;

    // Utility
    void wakeWorker() noexcept;
    void uploadPackage(std::unique_ptr<OtlpPackage> package) noexcept;
    void queueRetry(std::unique_ptr<OtlpPackage> package) noexcept;
    std::unique_ptr<OtlpPackage> buildPackage(const std::vector<std::unique_ptr<SpanData>> &spans) const noexcept;
};
}
