//
//  Tracer.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "Tracer.h"

#import "SpanAttributes.h"
#import "Utils.h"
#import "BugsnagPerformanceSpan+Private.h"
#import "Instrumentation/NetworkInstrumentation/NetworkInstrumentation.h"
#import "Instrumentation/ViewLoadInstrumentation/ViewLoadInstrumentation.h"
#import "BugsnagPerformanceLibrary.h"
#import "FrameRateMetrics/FrameMetricsCollector.h"
#import "BugsnagPerformanceSpanContext+Private.h"
#import <algorithm>

using namespace bugsnag;

BugsnagPerformanceSpan *
Tracer::startSpan(NSString *name,
                  const SpanOptions &options,
                  BSGTriState defaultFirstClass,
                  NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept {
    return plainSpanFactory_->startSpan(name, options, defaultFirstClass, @{}, conditionsToEndOnClose);
}

BugsnagPerformanceSpan *
Tracer::startCustomSpan(NSString *name,
                        const SpanOptions &options) noexcept {
    return startSpan(name, options, BSGTriStateYes, @[]);
}

BugsnagPerformanceSpan *
Tracer::startViewLoadSpan(BugsnagPerformanceViewType viewType,
                          NSString *className,
                          const SpanOptions &options) noexcept {
    return viewLoadSpanFactory_->startViewLoadSpan(viewType,
                                                   className,
                                                   nil,
                                                   options,
                                                   @{});
}

BugsnagPerformanceSpan *
Tracer::startNetworkSpan(NSString *httpMethod,
                         const SpanOptions &options) noexcept {
    return networkSpanFactory_->startNetworkSpan(httpMethod, options, @{});
}

BugsnagPerformanceSpan *
Tracer::startViewLoadPhaseSpan(NSString *className,
                               NSString *phase,
                               BugsnagPerformanceSpanContext *parentContext,
                               NSArray<BugsnagPerformanceSpanCondition*> *conditionsToEndOnClose) noexcept {
    return viewLoadSpanFactory_->startViewLoadPhaseSpan(className,
                                                        parentContext,
                                                        phase,
                                                        conditionsToEndOnClose);
}

PlainSpanFactoryCallbacks *
Tracer::createPlainSpanFactoryCallbacks() noexcept {
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
Tracer::createViewLoadSpanFactoryCallbacks() noexcept {
    __block auto blockThis = this;
    auto callbacks = [ViewLoadSpanFactoryCallbacks new];
    callbacks.getViewLoadParentSpan = ^GetViewLoadParentSpanCallbackResult *() {
        if (blockThis->getAppStartupInstrumentationState_ != nil) {
            AppStartupInstrumentationStateSnapshot *appStartupState = blockThis->getAppStartupInstrumentationState_();
            if (appStartupState.isInProgress && !appStartupState.hasFirstView) {
                GetViewLoadParentSpanCallbackResult *result = [GetViewLoadParentSpanCallbackResult new];
                result.span = appStartupState.uiInitSpan;
                result.isLegacy = appStartupState.isLegacy;
                return result;
            }
        }
        return nil;
    };
    callbacks.isViewLoadInProgress = ^BOOL() {
        return blockThis->spanStore_->hasSpanOnCurrentStack(@"bugsnag.span.category", @"view_load");
    };
    
    auto onViewLoadSpanStarted = ^(NSString * _Nonnull className) {
        if (onViewLoadSpanStarted_ != nil) {
            onViewLoadSpanStarted_(className);
        }
    };
    
    callbacks.onViewLoadSpanStarted = onViewLoadSpanStarted;
    
    return callbacks;
}
