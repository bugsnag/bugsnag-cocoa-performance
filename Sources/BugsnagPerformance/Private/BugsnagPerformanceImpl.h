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
#import "RetryQueue.h"

#import <mutex>

namespace bugsnag {
class BugsnagPerformanceImpl {
public:
    BugsnagPerformanceImpl() noexcept;
    
    bool start(BugsnagPerformanceConfiguration *configuration, NSError **error) noexcept;
    
    void reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept {
        tracer_.reportNetworkSpan(task, metrics);
    }

    BugsnagPerformanceSpan *startSpan(NSString *name);

    BugsnagPerformanceSpan *startSpan(NSString *name, BugsnagPerformanceSpanOptions *options);

    BugsnagPerformanceSpan *startViewLoadSpan(NSString *name, BugsnagPerformanceViewType viewType);

    BugsnagPerformanceSpan *startViewLoadSpan(NSString *name,
                                              BugsnagPerformanceViewType viewType,
                                              BugsnagPerformanceSpanOptions *options);

    void startViewLoadSpan(UIViewController *controller, BugsnagPerformanceSpanOptions *options);

    void endViewLoadSpan(UIViewController *controller, NSDate *endTime);

    void reportNetworkRequestSpan(NSURLSessionTask * task, NSURLSessionTaskMetrics *metrics) {
        tracer_.reportNetworkSpan(task, metrics);
    }

    void onSpanStarted() noexcept;

private:
    bool started_;
    std::mutex instanceMutex_;
    std::shared_ptr<Batch> batch_;
    std::shared_ptr<class Sampler> sampler_;
    Tracer tracer_;
    Worker *worker_;
    std::shared_ptr<Persistence> persistence_;
    std::shared_ptr<PersistentState> persistentState_;
    std::shared_ptr<OtlpUploader> uploader_;
    std::unique_ptr<RetryQueue> retryQueue_;
    NSDictionary *resourceAttributes_;
    bool shouldPersistState_;
    std::mutex viewControllersToSpansMutex_;
    NSMapTable<UIViewController *, BugsnagPerformanceSpan *> *viewControllersToSpans_;
    CFAbsoluteTime probabilityExpiry_;
    CFAbsoluteTime pausePValueRequestsUntil_;

    // Tasks
    NSArray<Task> *buildInitialTasks();
    NSArray<Task> *buildRecurringTasks();
    bool sendCurrentBatchTask();
    bool sendRetriesTask();
    bool sendPValueRequestTask();
    bool maybePersistStateTask();

    // Event reactions
    void onBatchFull() noexcept;
    void onConnectivityChanged(Reachability::Connectivity connectivity) noexcept;
    void onProbabilityChanged(double newProbability) noexcept;
    void onPersistentStateChanged() noexcept;
    void onFilesystemError() noexcept;

    // Utility
    void wakeWorker() noexcept;
    void uploadPValueRequest() noexcept;
    void uploadPackage(std::unique_ptr<OtlpPackage> package, bool isRetry) noexcept;

public: // For testing
    NSUInteger testing_getViewControllersToSpansCount() { return viewControllersToSpans_.count; };
};
}
