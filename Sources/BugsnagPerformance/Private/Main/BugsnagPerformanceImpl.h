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

#import "MainModule.h"

#import "../Core/Span/BugsnagPerformanceSpan+Private.h"
#import "../Upload/Otlp/OtlpUploader.h"
#import "../Core/Sampler/Sampler.h"
#import "../Core/Worker/Worker.h"
#import "../Utils/Persistence.h"
#import "../Core/Sampler/PersistentState.h"
#import "../Utils/Reachability.h"
#import "../Upload/RetryQueue.h"
#import "../Utils/AppStateTracker.h"
#import "../Core/PhasedStartup.h"
#import "../Instrumentation/Instrumentation.h"
#import "../Core/Attributes/ResourceAttributes.h"
#import "../Instrumentation/NetworkInstrumentation/System/NetworkHeaderInjector.h"
#import "../Upload/Otlp/OtlpTraceEncoding.h"
#import "../Metrics/FrameMetrics/FrameMetricsCollector.h"
#import "../Core/SpanConditions/ConditionTimeoutExecutor.h"
#import "../Metrics/SystemMetrics/SystemInfoSampler.h"
#import "../PluginSupport/SpanControl/BSGCompositeSpanControlProvider.h"
#import "../PluginSupport/PluginManager/BSGPluginManager.h"
#import "../Core/SpanFactory/AppStartup/AppStartupSpanFactoryImpl.h"
#import "../Core/SpanFactory/ViewLoad/ViewLoadSpanFactoryImpl.h"
#import "../Core/SpanFactory/Network/NetworkSpanFactoryImpl.h"
#import "../Core/SpanLifecycle/SpanLifecycleHandlerImpl.h"
#import "../Core/SpanStore/SpanStoreImpl.h"

#import <mutex>

namespace bugsnag {

class BugsnagPerformanceImpl: public PhasedStartup {
public:
    BugsnagPerformanceImpl(std::shared_ptr<MainModule> mainModule) noexcept
    : mainModule_(mainModule) {}
    
    ~BugsnagPerformanceImpl() {};
    
    void initialize() noexcept;

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
    
    BugsnagPerformanceSpanContext *currentContext() noexcept {
        return mainModule_->getCoreModule()->getSpanStackingHandler()->currentSpan();
    }

    void didStartViewLoadSpan(NSString *name) noexcept { mainModule_->getInstrumentationModule()->getInstrumentation()->didStartViewLoadSpan(name); }
    void willCallMainFunction() noexcept { mainModule_->getInstrumentationModule()->getInstrumentation()->willCallMainFunction(); }
    
    id<BugsnagPerformanceSpanControl> getSpanControls(BugsnagPerformanceSpanQuery *query) noexcept {
        return [mainModule_->getPluginSupportModule()->getSpanControlProvider() getSpanControlsWithQuery:query];
    }

    void loadingIndicatorWasAdded(BugsnagPerformanceLoadingIndicatorView *loadingViewIndicator) noexcept;

private:
    BugsnagPerformanceConfiguration *configuration_;
    
    std::shared_ptr<MainModule> mainModule_;
    NSMapTable<UIViewController *, BugsnagPerformanceSpan *> *viewControllersToSpans_;
    std::mutex viewControllersToSpansMutex_;
    std::atomic<bool> isStarted_{false};

public: // For testing
    NSUInteger testing_getViewControllersToSpansCount() { return viewControllersToSpans_.count; };
    NSUInteger testing_getBatchCount() {
        return mainModule_->getCoreModule()->getBatch()->count();
    };
};

}
