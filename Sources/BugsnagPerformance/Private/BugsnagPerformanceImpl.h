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
#import <BugsnagPerformance/BugsnagPerformanceLoadingIndicatorView.h>

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
#import "PhasedStartup.h"
#import "Instrumentation/Instrumentation.h"
#import "ResourceAttributes.h"
#import "NetworkHeaderInjector.h"
#import "OtlpTraceEncoding.h"
#import "FrameRateMetrics/FrameMetricsCollector.h"
#import "ConditionTimeoutExecutor.h"
#import "SystemInfoSampler.h"
#import "SpanControl/BSGCompositeSpanControlProvider.h"
#import "BSGPluginManager.h"

#import <mutex>

namespace bugsnag {

class BugsnagPerformanceImpl: public PhasedStartup {
public:
    BugsnagPerformanceImpl(std::shared_ptr<Reachability> reachability,
                           AppStateTracker *appStateTracker) noexcept;
    virtual ~BugsnagPerformanceImpl();

    void earlyConfigure(BSGEarlyConfiguration *config) noexcept;
    void earlySetup() noexcept;
    void configure(BugsnagPerformanceConfiguration * config) noexcept;
    void preStartSetup() noexcept;
    void start() noexcept;

    void reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept;

    BugsnagPerformanceSpan *startCustomSpan(NSString *name) noexcept;

    BugsnagPerformanceSpan *startCustomSpan(NSString *name, BugsnagPerformanceSpanOptions *options) noexcept;

    BugsnagPerformanceSpan *startViewLoadSpan(NSString *name, BugsnagPerformanceViewType viewType) noexcept;

    BugsnagPerformanceSpan *startViewLoadSpan(NSString *name,
                                              BugsnagPerformanceViewType viewType,
                                              BugsnagPerformanceSpanOptions *options) noexcept;

    BugsnagPerformanceSpan *startViewLoadPhaseSpan(NSString *className, NSString *phase,
                                                   BugsnagPerformanceSpanContext *parentContext) noexcept;

    void startViewLoadSpan(UIViewController *controller, BugsnagPerformanceSpanOptions *options) noexcept;

    void endViewLoadSpan(UIViewController *controller, NSDate *endTime) noexcept;

    void onSpanStarted() noexcept;
    
    BugsnagPerformanceSpanContext *currentContext() noexcept {
        return spanStackingHandler_->currentSpan();
    }

    void setOnViewLoadSpanStarted(std::function<void(NSString *)> onViewLoadSpanStarted) noexcept {
        tracer_->setOnViewLoadSpanStarted(onViewLoadSpanStarted);
    }

    void didStartViewLoadSpan(NSString *name) noexcept { instrumentation_->didStartViewLoadSpan(name); }
    void willCallMainFunction() noexcept { instrumentation_->willCallMainFunction(); }
    
    id<BugsnagPerformanceSpanControl> getSpanControls(BugsnagPerformanceSpanQuery *query) noexcept {
        return [spanControlProvider_ getSpanControlsWithQuery:query];
    }

    void loadingIndicatorWasAdded(BugsnagPerformanceLoadingIndicatorView *loadingViewIndicator) noexcept;
    void loadingIndicatorWasRemoved(BugsnagPerformanceLoadingIndicatorView *loadingViewIndicator) noexcept;

private:
    std::shared_ptr<Persistence> persistence_;
    std::shared_ptr<PersistentState> persistentState_;
    std::shared_ptr<SpanStackingHandler> spanStackingHandler_;
    std::shared_ptr<Reachability> reachability_;
    std::shared_ptr<Batch> batch_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    std::shared_ptr<class Sampler> sampler_;
    std::shared_ptr<NetworkHeaderInjector> networkHeaderInjector_;
    FrameMetricsCollector *frameMetricsCollector_;
    std::shared_ptr<ConditionTimeoutExecutor> conditionTimeoutExecutor_;
    BSGCompositeSpanControlProvider *spanControlProvider_;
    BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> *spanStartCallbacks_;
    BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> *spanEndCallbacks_;
    std::shared_ptr<Tracer> tracer_;
    std::unique_ptr<RetryQueue> retryQueue_;
    AppStateTracker *appStateTracker_;
    NSMapTable<UIViewController *, BugsnagPerformanceSpan *> *viewControllersToSpans_;
    std::shared_ptr<Instrumentation> instrumentation_;
    Worker *worker_;
    std::shared_ptr<PersistentDeviceID> deviceID_;
    std::shared_ptr<ResourceAttributes> resourceAttributes_;
    BugsnagPerformanceNetworkRequestCallback networkRequestCallback_;
    OtlpTraceEncoding traceEncoding_;

    BugsnagPerformanceConfiguration *configuration_;
    BSGPluginManager *pluginManager_;
    std::shared_ptr<OtlpUploader> uploader_;
    std::mutex viewControllersToSpansMutex_;
    CFAbsoluteTime probabilityExpiry_{0};
    CFAbsoluteTime pausePValueRequestsUntil_{0};
    NSTimer *workerTimer_{nil};
    NSTimeInterval performWorkInterval_{0};
    CFTimeInterval probabilityValueExpiresAfterSeconds_{0};
    CFTimeInterval probabilityRequestsPauseForSeconds_{0};
    uint64_t maxPackageContentLength_{1000000};
    std::atomic<bool> isStarted_{false};
    bool hasCheckedAppStartDuration_{false};

    // Tasks
    NSArray<Task> *buildInitialTasks() noexcept;
    NSArray<Task> *buildRecurringTasks() noexcept;
    bool sendCurrentBatchTask() noexcept;
    bool sendRetriesTask() noexcept;
    bool sweepTracerTask() noexcept;

    // Periodic Measurements
    SystemInfoSampler systemInfoSampler_;

    // Event reactions
    void onBatchFull() noexcept;
    void onConnectivityChanged(Reachability::Connectivity connectivity) noexcept;
    void onProbabilityChanged(double newProbability) noexcept;
    void onFilesystemError() noexcept;
    void onWorkInterval() noexcept;
    void onAppEnteredForeground() noexcept;
    void onAppEnteredBackground() noexcept;
    void onAppFinishedLaunching() noexcept;

    // Utility
    void checkAppStartDuration() noexcept;
    void wakeWorker() noexcept;
    void uploadPValueRequest() noexcept;
    void uploadPackage(std::unique_ptr<OtlpPackage> package, bool isRetry) noexcept;
    void possiblyMakeSpanCurrent(BugsnagPerformanceSpan *span, SpanOptions &options);
    NSMutableArray<BugsnagPerformanceSpan *> *
      sendableSpans(NSMutableArray<BugsnagPerformanceSpan *> *spans) noexcept;
    bool shouldSampleCPU(BugsnagPerformanceSpan *span) noexcept;
    bool shouldSampleMemory(BugsnagPerformanceSpan *span) noexcept;

public: // For testing
    void testing_setProbability(double probability) { onProbabilityChanged(probability); };
    NSUInteger testing_getViewControllersToSpansCount() { return viewControllersToSpans_.count; };
    NSUInteger testing_getBatchCount() { return batch_->count(); };
};

}
