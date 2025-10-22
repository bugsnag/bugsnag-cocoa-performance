//
//  CoreModule.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "CoreModule.h"

using namespace bugsnag;

CoreModule::~CoreModule() {
    [workerTimer_ invalidate];
}

#pragma mark PhasedStartup

void
CoreModule::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    persistentState_->earlyConfigure(config);
    plainSpanFactory_->earlyConfigure(config);
    resourceAttributes_->earlyConfigure(config);
    batch_->earlyConfigure(config);
    spanLifecycleHandler_->earlyConfigure(config);
    networkSpanReporter_->earlyConfigure(config);
    [worker_ earlyConfigure:config];
}

void
CoreModule::earlySetup() noexcept {
    persistentState_->earlySetup();
    plainSpanFactory_->earlySetup();
    resourceAttributes_->earlySetup();
    batch_->earlySetup();
    spanLifecycleHandler_->earlySetup();
    networkSpanReporter_->earlySetup();
    [worker_ earlySetup];
}

void
CoreModule::configure(BugsnagPerformanceConfiguration *config) noexcept {
    configuration_ = config;
    probabilityValueExpiresAfterSeconds_ = config.internal.probabilityValueExpiresAfterSeconds;
    probabilityRequestsPauseForSeconds_ = config.internal.probabilityRequestsPauseForSeconds;
    persistentState_->configure(config);
    plainSpanFactory_->configure(config);
    resourceAttributes_->configure(config);
    batch_->configure(config);
    spanLifecycleHandler_->configure(config);
    networkSpanReporter_->configure(config);
    [worker_ configure:config];
}

void
CoreModule::preStartSetup() noexcept {
    persistentState_->preStartSetup();
    plainSpanFactory_->preStartSetup();
    resourceAttributes_->preStartSetup();
    batch_->preStartSetup();
    spanLifecycleHandler_->preStartSetup();
    networkSpanReporter_->preStartSetup();
    [worker_ preStartSetup];
}

void
CoreModule::start() noexcept {
    isStarted_ = true;
    persistentState_->start();
    
    double samplingProbability = persistentState_->probability();
    if (configuration_.samplingProbability != nil) {
        samplingProbability = [configuration_.samplingProbability doubleValue];
    }
    sampler_->setProbability(samplingProbability);
    
    plainSpanFactory_->start();
    resourceAttributes_->start();
    batch_->start();
    spanLifecycleHandler_->start();
    networkSpanReporter_->start();
    [worker_ start];
    
    __block auto blockThis = this;
    auto initialWorkDelay = configuration_.internal.initialRecurringWorkDelay;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(initialWorkDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [blockThis->worker_ wake];
        blockThis->workerTimer_ = [NSTimer scheduledTimerWithTimeInterval:blockThis->configuration_.internal.performWorkInterval
                                                       repeats:YES
                                                         block:^(NSTimer *) {
            blockThis->batch_->allowDrain();
            [blockThis->worker_ wake];
        }];
    });
    batch_->setBatchFullCallback(^{
        [blockThis->worker_ wake];
    });
}

#pragma mark Module

void
CoreModule::setUp() noexcept {
    batch_ = std::make_shared<Batch>();
    persistentState_ = std::make_shared<PersistentState>(persistence_);
    spanAttributesProvider_ = std::make_shared<SpanAttributesProvider>(appStateTracker_,
                                                                       reachability_);
    spanStackingHandler_ = std::make_shared<SpanStackingHandler>();
    sampler_ = std::make_shared<Sampler>();
    conditionTimeoutExecutor_ = std::make_shared<ConditionTimeoutExecutor>();
    plainSpanFactory_ = std::make_shared<PlainSpanFactoryImpl>(sampler_, spanStackingHandler_, spanAttributesProvider_);
    appStartupSpanFactory_ = std::make_shared<AppStartupSpanFactoryImpl>(plainSpanFactory_, spanAttributesProvider_);
    viewLoadSpanFactory_ = std::make_shared<ViewLoadSpanFactoryImpl>(plainSpanFactory_, spanAttributesProvider_);
    networkSpanFactory_ = std::make_shared<NetworkSpanFactoryImpl>(plainSpanFactory_, spanAttributesProvider_);
    
    spanStartCallbacks_ = [BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> new];
    spanEndCallbacks_ = [BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> new];
    spanStore_ = std::make_shared<SpanStoreImpl>(spanStackingHandler_);
    spanLifecycleHandler_ = std::make_shared<SpanLifecycleHandlerImpl>(sampler_,
                                                                       spanStore_,
                                                                       conditionTimeoutExecutor_,
                                                                       plainSpanFactory_,
                                                                       batch_,
                                                                       spanStartCallbacks_,
                                                                       spanEndCallbacks_);
    resourceAttributes_ = std::make_shared<ResourceAttributes>(deviceID_);
    networkSpanReporter_ = std::make_shared<NetworkSpanReporterImpl>(spanAttributesProvider_,
                                                                     networkSpanFactory_);
    worker_ = [[Worker alloc] initWithInitialTasks:initialTasks_ recurringTasks:recurringTasks_];
}

#pragma mark Tasks

UpdateProbabilityTask
CoreModule::getUpdateProbabilityTask() noexcept {
    __block auto blockThis = this;
    return ^(double newProbability) {
        if (blockThis->configuration_.samplingProbability != nil) {
            BSGLogTrace(@"CoreModule::getUpdateProbabilityTask: configuration_.samplingProbability != nil");
            return;
        }
        blockThis->probabilityExpiry_ = CFAbsoluteTimeGetCurrent() + probabilityValueExpiresAfterSeconds_;
        blockThis->sampler_->setProbability(newProbability);
        blockThis->persistentState_->setProbability(newProbability);
    };
}

UpdateConnectivityTask
CoreModule::getUpdateConnectivityTask() noexcept {
    __block auto blockThis = this;
    return ^(Reachability::Connectivity connectivity) {
        switch (connectivity) {
            case Reachability::Cellular: case Reachability::Wifi:
                [blockThis->worker_ wake];
                break;
            case Reachability::Unknown: case Reachability::None:
                // Don't care
                break;
        }
    };
}
    
#pragma mark AppLifecycleListener

void
CoreModule::onAppEnteredBackground() noexcept {
    spanLifecycleHandler_->onAppEnteredBackground();
}

void
CoreModule::onAppEnteredForeground() noexcept {
    if (!isStarted_) {
        return;
    }

    batch_->allowDrain();
    [worker_ wake];
}

#pragma mark Private

PlainSpanFactoryCallbacks *
CoreModule::createPlainSpanFactoryCallbacks() noexcept {
    __block auto blockThis = this;
    auto callbacks = [PlainSpanFactoryCallbacks new];
    callbacks.onSpanStarted = ^(BugsnagPerformanceSpan * _Nonnull span, const SpanOptions &options) {
        blockThis->spanLifecycleHandler_->onSpanStarted(span, options);
    };
    
    callbacks.onSpanEndSet = ^(BugsnagPerformanceSpan * _Nonnull span) {
        blockThis->spanLifecycleHandler_->onSpanEndSet(span);
    };
    
    callbacks.onSpanClosed = ^(BugsnagPerformanceSpan * _Nonnull span) {
        blockThis->spanLifecycleHandler_->onSpanClosed(span);
    };
    
    callbacks.onSpanBlocked = ^BugsnagPerformanceSpanCondition * _Nullable(BugsnagPerformanceSpan * _Nonnull span, NSTimeInterval timeout) {
        return blockThis->spanLifecycleHandler_->onSpanBlocked(span, timeout);
    };
    
    callbacks.onSpanCancelled = ^(BugsnagPerformanceSpan * _Nonnull span) {
        blockThis->spanLifecycleHandler_->onSpanCancelled(span);
    };

    return callbacks;
}

ViewLoadSpanFactoryCallbacks *
CoreModule::createViewLoadSpanFactoryCallbacks(HandleStringTask onViewLoadSpanStartedTask,
                                               GetAppStartupStateSnapshot getAppStartupStateSnapshot) noexcept {
    __block auto blockThis = this;
    auto callbacks = [ViewLoadSpanFactoryCallbacks new];
    callbacks.getViewLoadParentSpan = ^BugsnagPerformanceSpan *() {
        if (getAppStartupStateSnapshot != nil) {
            AppStartupInstrumentationStateSnapshot *appStartupState = getAppStartupStateSnapshot();
            if (appStartupState.isInProgress && !appStartupState.hasFirstView) {
                return appStartupState.uiInitSpan;
            }
        }
        return nil;
    };
    callbacks.isViewLoadInProgress = ^BOOL() {
        return blockThis->spanStore_->hasSpanOnCurrentStack(@"bugsnag.span.category", @"view_load");
    };
    
    auto onViewLoadSpanStarted = ^(NSString * _Nonnull className) {
        if (onViewLoadSpanStartedTask != nil) {
            onViewLoadSpanStartedTask(className);
        }
    };
    
    callbacks.onViewLoadSpanStarted = onViewLoadSpanStarted;
    
    return callbacks;
}
