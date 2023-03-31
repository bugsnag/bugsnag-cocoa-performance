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
#import "AppStateTracker.h"

#import <mutex>

namespace bugsnag {
class BugsnagPerformanceImpl {
public:
    BugsnagPerformanceImpl() noexcept;

    void start(BugsnagPerformanceConfiguration *configuration) noexcept;

    void reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept {
        tracer_.reportNetworkSpan(task, metrics);
    }

    BugsnagPerformanceSpan *startSpan(NSString *name);

    BugsnagPerformanceSpan *startSpan(NSString *name, BugsnagPerformanceSpanOptions *options);

    BugsnagPerformanceSpan *startViewLoadSpan(NSString *name, BugsnagPerformanceViewType viewType);

    BugsnagPerformanceSpan *startViewLoadSpan(NSString *name,
                                              BugsnagPerformanceViewType viewType,
                                              BugsnagPerformanceSpanOptions *options);
    void cancelQueuedSpan(BugsnagPerformanceSpan *span);

    void startViewLoadSpan(UIViewController *controller, BugsnagPerformanceSpanOptions *options);

    void endViewLoadSpan(UIViewController *controller, NSDate *endTime);

    void reportNetworkRequestSpan(NSURLSessionTask * task, NSURLSessionTaskMetrics *metrics) {
        tracer_.reportNetworkSpan(task, metrics);
    }

    BugsnagPerformanceSpan *startAppStartSpan(NSString *name, SpanOptions options);

    void onSpanStarted() noexcept;

private:
    bool started_{false};
    std::mutex instanceMutex_;
    std::shared_ptr<Batch> batch_;
    std::shared_ptr<class Sampler> sampler_;
    Tracer tracer_;
    Worker *worker_{nil};
    BugsnagPerformanceConfiguration *configuration_;
    std::shared_ptr<Persistence> persistence_;
    std::shared_ptr<PersistentState> persistentState_;
    std::shared_ptr<OtlpUploader> uploader_;
    std::unique_ptr<RetryQueue> retryQueue_;
    NSDictionary *resourceAttributes_{nil};
    std::atomic<bool> shouldPersistState_{false};
    std::mutex viewControllersToSpansMutex_;
    NSMapTable<UIViewController *, BugsnagPerformanceSpan *> *viewControllersToSpans_;
    CFAbsoluteTime probabilityExpiry_{0};
    CFAbsoluteTime pausePValueRequestsUntil_{0};
    NSTimer *workerTimer_{nil};
    AppStateTracker *appStateTracker_{nil};

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
    void onWorkInterval() noexcept;
    void onAppEnteredForeground() noexcept;

    // Utility
    void wakeWorker() noexcept;
    void uploadPValueRequest() noexcept;
    void uploadPackage(std::unique_ptr<OtlpPackage> package, bool isRetry) noexcept;

public: // For testing
    NSUInteger testing_getViewControllersToSpansCount() { return viewControllersToSpans_.count; };
};

std::shared_ptr<BugsnagPerformanceImpl> getBugsnagPerformanceImpl() noexcept;

}
