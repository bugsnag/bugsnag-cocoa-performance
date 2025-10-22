//
//  MainModule.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "MainModule.h"

using namespace bugsnag;

#pragma mark PhasedStartup

void
MainModule::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    // Do MetricsModule first so that any early spans will always have a bounding sample
    metricsModule_->earlyConfigure(config);
    utilsModule_->earlyConfigure(config);
    coreModule_->earlyConfigure(config);
    instrumentationModule_->earlyConfigure(config);
    uploadModule_->earlyConfigure(config);
    pluginSupportModule_->earlyConfigure(config);
    pluginsModule_->earlyConfigure(config);
    crossTalkAPIModule_->earlyConfigure(config);
    
    // Configure these here because notifications may arrive
    // before Bugsnag is started.
    __block auto blockThis = this;
    utilsModule_->getAppStateTracker().onAppFinishedLaunching = ^{
        blockThis->onAppFinishedLaunching();
    };

    utilsModule_->getAppStateTracker().onTransitionToBackground = ^{
        blockThis->onAppEnteredBackground();
    };

    utilsModule_->getAppStateTracker().onTransitionToForeground = ^{
        blockThis->onAppEnteredForeground();
    };
}

void
MainModule::earlySetup() noexcept {
    metricsModule_->earlySetup();
    utilsModule_->earlySetup();
    coreModule_->earlySetup();
    instrumentationModule_->earlySetup();
    uploadModule_->earlySetup();
    pluginSupportModule_->earlySetup();
    pluginsModule_->earlySetup();
    crossTalkAPIModule_->earlySetup();
}

void
MainModule::configure(BugsnagPerformanceConfiguration *config) noexcept {
    metricsModule_->configure(config);
    utilsModule_->configure(config);
    coreModule_->configure(config);
    instrumentationModule_->configure(config);
    uploadModule_->configure(config);
    pluginSupportModule_->configure(config);
    pluginsModule_->configure(config);
    crossTalkAPIModule_->configure(config);
}

void
MainModule::preStartSetup() noexcept {
    metricsModule_->preStartSetup();
    utilsModule_->preStartSetup();
    coreModule_->preStartSetup();
    instrumentationModule_->preStartSetup();
    uploadModule_->preStartSetup();
    pluginSupportModule_->preStartSetup();
    pluginsModule_->preStartSetup();
    crossTalkAPIModule_->preStartSetup();
}

void
MainModule::start() noexcept {
    metricsModule_->start();
    utilsModule_->start();
    coreModule_->start();
    instrumentationModule_->start();
    uploadModule_->start();
    pluginSupportModule_->start();
    pluginsModule_->start();
    crossTalkAPIModule_->start();
}

#pragma mark Module

void
MainModule::setUp() noexcept {
    initializeModules();
}

#pragma mark AppLifecycleListener

void
MainModule::onAppFinishedLaunching() noexcept {
    coreModule_->onAppFinishedLaunching();
    instrumentationModule_->onAppFinishedLaunching();
    metricsModule_->onAppFinishedLaunching();
}

void
MainModule::onAppEnteredBackground() noexcept {
    coreModule_->onAppEnteredBackground();
    instrumentationModule_->onAppEnteredBackground();
    metricsModule_->onAppEnteredBackground();
}

void
MainModule::onAppEnteredForeground() noexcept {
    coreModule_->onAppEnteredForeground();
    instrumentationModule_->onAppEnteredForeground();
    metricsModule_->onAppEnteredForeground();
}

#pragma mark Private

void
MainModule::initializeModules() noexcept {
    utilsModule_ = std::make_shared<UtilsModule>();
    utilsModule_->setUp();
    coreModule_ = std::make_shared<CoreModule>(utilsModule_->getAppStateTracker(),
                                               utilsModule_->getReachability(),
                                               utilsModule_->getPersistence(),
                                               utilsModule_->getDeviceID());
    coreModule_->initialize(buildInitialTasks(), buildRecurringTasks()); // TODO
    coreModule_->setUp();
    instrumentationModule_ = std::make_shared<InstrumentationModule>(coreModule_->getAppStartupSpanFactory(),
                                                                     coreModule_->getViewLoadSpanFactory(),
                                                                     coreModule_->getNetworkSpanFactory(),
                                                                     coreModule_->getSpanAttributesProvider(),
                                                                     coreModule_->getSpanStackingHandler(),
                                                                     coreModule_->getSampler());
    instrumentationModule_->setUp();
    metricsModule_ = std::make_shared<MetricsModule>();
    metricsModule_->setUp();
    
    crossTalkAPIModule_ = std::make_shared<CrossTalkAPIModule>(coreModule_->getPlainSpanFactory(),
                                                               coreModule_->getSpanStackingHandler());
    crossTalkAPIModule_->setUp();
    
    pluginsModule_ = std::make_shared<PluginsModule>(instrumentationModule_->getInstrumentation());
    pluginsModule_->setUp();
    
    pluginSupportModule_ = std::make_shared<PluginSupportModule>();
    pluginSupportModule_->setUp();
    
    uploadModule_ = std::make_shared<UploadModule>(utilsModule_->getPersistence());
    uploadModule_->setUp();
    
    utilsModule_->initializeComponentsCallbacks(coreModule_->getUpdateConnectivityTask());
    uploadModule_->initializeComponentsCallbacks(utilsModule_->getClearPersistentDataTask(),
                                                 coreModule_->getUpdateProbabilityTask());
    coreModule_->initializeComponentsCallbacks(metricsModule_->getCurrentFrameMetricsSnapshotTask(),
                                               instrumentationModule_->getAppStartupStateSnapshotTask(),
                                               instrumentationModule_->getHandleViewLoadSpanStartedTask());
    pluginSupportModule_->installPlugins(pluginsModule_->getDefaultPluginsTask()());
}

NSArray<Task> *
MainModule::buildInitialTasks() noexcept {
//    __block auto blockThis = this;
    return @[
//        ^bool() {
//            [blockThis->pluginSupportModule_->getPluginManager() startPlugins];
//            return true;
//        },
    ];
}

NSArray<Task> *
MainModule::buildRecurringTasks() noexcept {
//    __block auto blockThis = this;
    return @[
//        ^bool() { return blockThis->sendCurrentBatchTask(); },
//        ^bool() { return blockThis->sendRetriesTask(); },
//        ^bool() { return blockThis->sweepTracerTask(); },
    ];
}
//
//NSMutableArray<BugsnagPerformanceSpan *> *
//BugsnagPerformanceImpl::sendableSpans(NSMutableArray<BugsnagPerformanceSpan *> *spans) noexcept {
//    NSMutableArray<BugsnagPerformanceSpan *> *sendableSpans = [NSMutableArray arrayWithCapacity:spans.count];
//    for (BugsnagPerformanceSpan *span in spans) {
//        if (span.state != SpanStateAborted && sampler_->sampled(span)) {
//            [sendableSpans addObject:span];
//        }
//    }
//    return sendableSpans;
//}
//
//bool BugsnagPerformanceImpl::shouldSampleCPU(BugsnagPerformanceSpan *span) noexcept {
//    if (span.metricsOptions.cpu == BSGTriStateUnset) {
//        return span.firstClass == BSGTriStateYes;
//    }
//    return span.metricsOptions.cpu == BSGTriStateYes;
//}
//
//bool BugsnagPerformanceImpl::shouldSampleMemory(BugsnagPerformanceSpan *span) noexcept {
//    if (span.metricsOptions.memory == BSGTriStateUnset) {
//        return span.firstClass == BSGTriStateYes;
//    }
//    return span.metricsOptions.memory == BSGTriStateYes;
//}
//
//bool BugsnagPerformanceImpl::sendCurrentBatchTask() noexcept {
//    BSGLogDebug(@"BugsnagPerformanceImpl::sendCurrentBatchTask()");
//    auto origSpans = batch_->drain(false);
//#ifndef __clang_analyzer__
//    #pragma clang diagnostic ignored "-Wunused-variable"
//    size_t origSpansSize = origSpans.count;
//#endif
//    auto spans = sendableSpans(origSpans);
//    if (spans.count == 0) {
//#ifndef __clang_analyzer__
//        BSGLogTrace(@"BugsnagPerformanceImpl::sendCurrentBatchTask(): Nothing to send. origSpans size = %zu", origSpansSize);
//#endif
//        return false;
//    }
//    bool includeSamplingHeader = configuration_ == nil || configuration_.samplingProbability == nil;
//
//    // Delay so that the sampler has time to fetch one more sample.
//    BSGLogTrace(@"BugsnagPerformanceImpl::sendCurrentBatchTask(): Delaying %f seconds (%lld ns) before getting system info", SAMPLER_INTERVAL_SECONDS + 0.5, (int64_t)((SAMPLER_INTERVAL_SECONDS + 0.5) * NSEC_PER_SEC));
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((SAMPLER_INTERVAL_SECONDS + 0.5) * NSEC_PER_SEC)),
//                   dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
//        BSGLogTrace(@"BugsnagPerformanceImpl::sendCurrentBatchTask(): Delayed %f seconds, now getting system info", SAMPLER_INTERVAL_SECONDS + 0.5);
//        for(BugsnagPerformanceSpan *span: spans) {
//            auto samples = systemInfoSampler_.samplesAroundTimePeriod(span.actuallyStartedAt, span.actuallyEndedAt);
//            BSGLogTrace(@"BugsnagPerformanceImpl::sendCurrentBatchTask(): System info sample size = %zu", samples.size());
//            if (samples.size() >= 2) {
//                if (shouldSampleCPU(span)) {
//                    BSGLogTrace(@"BugsnagPerformanceImpl::sendCurrentBatchTask(): Getting CPU sample attributes for span %@", span.name);
//                    [span forceMutate:^() {
//                        [span internalSetMultipleAttributes:spanAttributesProvider_->cpuSampleAttributes(samples)];
//                    }];
//                }
//                if (shouldSampleMemory(span)) {
//                    BSGLogTrace(@"BugsnagPerformanceImpl::sendCurrentBatchTask(): Getting memory sample attributes for span %@", span.name);
//                    [span forceMutate:^() {
//                        [span internalSetMultipleAttributes:spanAttributesProvider_->memorySampleAttributes(samples)];
//                    }];
//                }
//            }
//        }
//
//#ifndef __clang_analyzer__
//        BSGLogTrace(@"BugsnagPerformanceImpl::sendCurrentBatchTask(): Sending %zu sampled spans (out of %zu)", origSpansSize, spans.count);
//#endif
//        uploadPackage(traceEncoding_.buildUploadPackage(spans, resourceAttributes_->get(), includeSamplingHeader), false);
//    });
//
//    return true;
//}
//
//bool BugsnagPerformanceImpl::sendRetriesTask() noexcept {
//    BSGLogDebug(@"BugsnagPerformanceImpl::sendRetriesTask()");
//    retryQueue_->sweep();
//
//    auto retries = retryQueue_->list();
//    if (retries.size() == 0) {
//        BSGLogTrace(@"BugsnagPerformanceImpl::sendRetriesTask(): No retries to send");
//        return false;
//    }
//
//    for (auto &&timestamp: retries) {
//        auto retry = retryQueue_->get(timestamp);
//        if (retry != nullptr) {
//            uploadPackage(std::move(retry), true);
//        }
//    }
//
//    // Retries never count as work, otherwise we'd loop endlessly on a network outage.
//    return false;
//}
//
//bool BugsnagPerformanceImpl::sweepTracerTask() noexcept {
//    BSGLogDebug(@"BugsnagPerformanceImpl::sweepTracerTask()");
//    spanStore_->sweep();
//    // Never auto-repeat this task, even if work was done; it can wait.
//    return false;
//}
