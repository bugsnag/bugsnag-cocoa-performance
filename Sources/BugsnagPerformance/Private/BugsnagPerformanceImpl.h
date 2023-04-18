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
#import "Configurable.h"

#import <mutex>

namespace bugsnag {
class BugsnagPerformanceImpl: public Configurable {
    friend class BugsnagPerformanceLibrary;
public:
    void configure(BugsnagPerformanceConfiguration *configuration) noexcept;
    void start() noexcept;

    void reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept {
        tracer_.reportNetworkSpan(task, metrics);
    }

    BugsnagPerformanceSpan *startSpan(NSString *name) noexcept;

    BugsnagPerformanceSpan *startSpan(NSString *name, BugsnagPerformanceSpanOptions *options) noexcept;

    BugsnagPerformanceSpan *startViewLoadSpan(NSString *name, BugsnagPerformanceViewType viewType) noexcept;

    BugsnagPerformanceSpan *startViewLoadSpan(NSString *name,
                                              BugsnagPerformanceViewType viewType,
                                              BugsnagPerformanceSpanOptions *options) noexcept;
    void cancelQueuedSpan(BugsnagPerformanceSpan *span) noexcept;

    void startViewLoadSpan(UIViewController *controller, BugsnagPerformanceSpanOptions *options) noexcept;

    void endViewLoadSpan(UIViewController *controller, NSDate *endTime) noexcept;

    void reportNetworkRequestSpan(NSURLSessionTask * task, NSURLSessionTaskMetrics *metrics) noexcept {
        tracer_.reportNetworkSpan(task, metrics);
    }

    BugsnagPerformanceSpan *startAppStartSpan(NSString *name, SpanOptions options) noexcept;

    void onSpanStarted() noexcept;

private:
    BugsnagPerformanceImpl(std::shared_ptr<Reachability> reachability,
                           AppStateTracker *appStateTracker) noexcept;

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
    std::shared_ptr<Reachability> reachability_;
    NSTimeInterval performWorkInterval_{0};
    CFTimeInterval probabilityValueExpiresAfterSeconds_{0};
    CFTimeInterval probabilityRequestsPauseForSeconds_{0};

    // Tasks
    NSArray<Task> *buildInitialTasks() noexcept;
    NSArray<Task> *buildRecurringTasks() noexcept;
    bool sendCurrentBatchTask() noexcept;
    bool sendRetriesTask() noexcept;
    bool sendPValueRequestTask() noexcept;
    bool maybePersistStateTask() noexcept;

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
    void testing_setProbability(double probability) { onProbabilityChanged(probability); };
    NSUInteger testing_getViewControllersToSpansCount() { return viewControllersToSpans_.count; };
    NSUInteger testing_getBatchCount() { return batch_->count(); };
    static std::shared_ptr<BugsnagPerformanceImpl> testing_newInstance() {
        return std::shared_ptr<BugsnagPerformanceImpl>(new BugsnagPerformanceImpl(Reachability::testing_newReachability(), [AppStateTracker new]));
    }
};

}
