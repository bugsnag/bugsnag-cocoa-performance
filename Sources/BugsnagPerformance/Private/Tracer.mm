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
#import <algorithm>

using namespace bugsnag;

void
Tracer::preStartSetup() noexcept {
    reprocessEarlySpans();
}

void Tracer::reprocessEarlySpans(void) {
    // Up until now nothing was configured, so all early spans have been kept.
    // Now that configuration is complete, force-drain all early spans and re-process them.
    auto toReprocess = batch_->drain(true);
    for (BugsnagPerformanceSpan *span in toReprocess) {
        if (span.state != SpanStateEnded) {
            continue;
        }
        if (!sampler_->sampled(span)) {
            [span abortUnconditionally];
            continue;
        }
        [span forceMutate:^() {
            callOnSpanEndCallbacks(span);
        }];
        if (span.state == SpanStateAborted) {
            [span abortUnconditionally];
            continue;
        }

        batch_->add(span);
    }
}

void
Tracer::abortAllOpenSpans() noexcept {
    potentiallyOpenSpans_->abortAllOpen();
}

void
Tracer::sweep() noexcept {
    constexpr unsigned minEntriesBeforeCompacting = 10000;
    if (potentiallyOpenSpans_->count() >= minEntriesBeforeCompacting) {
        potentiallyOpenSpans_->compact();
    }
}

BugsnagPerformanceSpan *
Tracer::startSpan(NSString *name,
                  const SpanOptions &options,
                  BSGTriState defaultFirstClass,
                  NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept {
    return plainSpanFactory_->startSpan(name, options, defaultFirstClass, @{}, conditionsToEndOnClose);
}

void Tracer::onSpanEndSet(BugsnagPerformanceSpan *span) {
    if (shouldInstrumentRendering(span)) {
        span.endFramerateSnapshot = [frameMetricsCollector_ currentSnapshot];
    }
}

void Tracer::onSpanClosed(BugsnagPerformanceSpan *span) {
    @synchronized (span) {
        for (BugsnagPerformanceSpanCondition *condition in span.conditionsToEndOnClose) {
            [condition closeWithEndTime:span.endTime];
        }
    }

    spanStackingHandler_->onSpanClosed(span.spanId);

    if(span.state == SpanStateAborted) {
        return;
    }

    if (!sampler_->sampled(span)) {
        [span abortUnconditionally];
        return;
    }

    if (span != nil && span.state == SpanStateEnded) {
        callOnSpanEndCallbacks(span);
        if (span.state == SpanStateAborted) {
            return;
        }
    }
    
    if (shouldInstrumentRendering(span)) {
        processFrameMetrics(span);
    }

    batch_->add(span);
}

BugsnagPerformanceSpanCondition *Tracer::onSpanBlocked(BugsnagPerformanceSpan *span, NSTimeInterval timeout) {
    if(span == nil || timeout <= 0) {
        return nil;
    }
    if (span.state != SpanStateOpen && !span.isBlocked) {
        return nil;
    }
    BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:span onClosedCallback:^(BugsnagPerformanceSpanCondition *c, CFAbsoluteTime endTime) {
        __strong BugsnagPerformanceSpan *strongSpan = c.span;
        if (strongSpan.state == SpanStateEnded && endTime > strongSpan.endAbsTime) {
            [strongSpan markEndAbsoluteTime:endTime];
        }
    } onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *c) {
        __strong BugsnagPerformanceSpan *strongSpan = c.span;
        @synchronized (this->blockedSpans_) {
            this->conditionTimeoutExecutor_->cancelTimeout(c);
        }
        @synchronized (c) {
            if (c.isActive) {
                return strongSpan;
            }
        }
        return nil;
    }];
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *c) {
        __strong BugsnagPerformanceSpan *strongSpan = c.span;
        if (strongSpan.state == SpanStateEnded && !strongSpan.isBlocked) {
            @synchronized (this->blockedSpans_) {
                [this->blockedSpans_ removeObject:strongSpan];
                this->conditionTimeoutExecutor_->cancelTimeout(c);
            }
            this->onSpanClosed(strongSpan);
        }
    }];
    this->conditionTimeoutExecutor_->sheduleTimeout(condition, timeout);
    return condition;
}

void Tracer::callOnSpanStartCallbacks(BugsnagPerformanceSpan *span) {
    if(span == nil) {
        return;
    }

    for (BugsnagPerformanceSpanStartCallback callback: [onSpanStartCallbacks_ objects]) {
        @try {
            callback(span);
        } @catch(NSException *e) {
            BSGLogError(@"Tracer::callOnSpanStartCallbacks: span onStart callback threw exception: %@", e);
        }
    }
}

void Tracer::callOnSpanEndCallbacks(BugsnagPerformanceSpan *span) {
    if(span == nil) {
        return;
    }
    if (span.state != SpanStateEnded) {
        return;
    }

    CFAbsoluteTime callbacksStartTime = CFAbsoluteTimeGetCurrent();
    for (BugsnagPerformanceSpanEndCallback callback: [onSpanEndCallbacks_ objects]) {
        BOOL shouldDiscardSpan = false;
        @try {
            shouldDiscardSpan = !callback(span);
        } @catch(NSException *e) {
            BSGLogError(@"Tracer::callOnSpanEndCallbacks: span OnEnd callback threw exception: %@", e);
            // We don't know whether they wanted to discard the span or not, so keep it.
            shouldDiscardSpan = false;
        }
        if(shouldDiscardSpan) {
            [span abortUnconditionally];
            return;
        }
    }
    CFAbsoluteTime callbacksEndTime = CFAbsoluteTimeGetCurrent();
    [span internalSetAttribute:@"bugsnag.span.callbacks_duration" withValue:@(intervalToNanoseconds(callbacksEndTime - callbacksStartTime))];
}

void Tracer::processFrameMetrics(BugsnagPerformanceSpan *span) noexcept {
    auto startSnapshot = span.startFramerateSnapshot;
    auto endSnapshot = span.endFramerateSnapshot;
    if (!shouldInstrumentRendering(span) ||
        startSnapshot == nil ||
        endSnapshot == nil) {
        return;
    }
    auto mergedSnapshot = [FrameMetricsSnapshot mergeWithStart:startSnapshot
                                                           end:endSnapshot];
    if (mergedSnapshot.totalFrames == 0) {
        return;
    }
    [span setAttribute:@"bugsnag.rendering.total_frames" withValue:@(mergedSnapshot.totalFrames)];
    [span setAttribute:@"bugsnag.rendering.slow_frames" withValue:@(mergedSnapshot.totalSlowFrames)];
    [span setAttribute:@"bugsnag.rendering.frozen_frames" withValue:@(mergedSnapshot.totalFrozenFrames)];
    
    auto frozenFrame = mergedSnapshot.firstFrozenFrame;
    while (frozenFrame != nil) {
        createFrozenFrameSpan(frozenFrame.startTime, frozenFrame.endTime, span);
        frozenFrame = frozenFrame != mergedSnapshot.lastFrozenFrame ? frozenFrame.next : nil;
    }
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

void Tracer::cancelQueuedSpan(BugsnagPerformanceSpan *span) noexcept {
    if (span) {
        [span abortUnconditionally];
        batch_->removeSpan(span.traceIdHi, span.traceIdLo, span.spanId);
        [blockedSpans_ removeObject:span];
    }
}

PlainSpanFactoryCallbacks *
Tracer::createPlainSpanFactoryCallbacks() noexcept {
    __block auto blockThis = this;
    auto callbacks = [PlainSpanFactoryCallbacks new];
    callbacks.onSpanStarted = ^(BugsnagPerformanceSpan * _Nonnull span, const SpanOptions &options) {
        if (blockThis->shouldInstrumentRendering(span)) {
            span.startFramerateSnapshot = [blockThis->frameMetricsCollector_ currentSnapshot];
        }
        if (options.makeCurrentContext) {
            blockThis->spanStackingHandler_->push(span);
        }
        blockThis->potentiallyOpenSpans_->add(span);
        
        blockThis->callOnSpanStartCallbacks(span);
        
        blockThis->onSpanStarted_();
    };
    
    callbacks.onSpanEndSet = ^(BugsnagPerformanceSpan * _Nonnull span) {
        blockThis->onSpanEndSet(span);
    };
    
    callbacks.onSpanClosed = ^(BugsnagPerformanceSpan * _Nonnull span) {
        if (!span.isBlocked) {
            blockThis->onSpanClosed(span);
        } else {
            @synchronized (this->blockedSpans_) {
                [blockedSpans_ addObject:span];
            }
        }
    };
    
    callbacks.onSpanBlocked = ^BugsnagPerformanceSpanCondition * _Nullable(BugsnagPerformanceSpan * _Nonnull span, NSTimeInterval timeout) {
        return blockThis->onSpanBlocked(span, timeout);
    };

    return callbacks;
}

ViewLoadSpanFactoryCallbacks *
Tracer::createViewLoadSpanFactoryCallbacks() noexcept {
    __block auto blockThis = this;
    auto callbacks = [ViewLoadSpanFactoryCallbacks new];
    callbacks.getViewLoadParentSpan = ^BugsnagPerformanceSpan *() {
        if (blockThis->getAppStartupInstrumentationState_ != nil) {
            AppStartupInstrumentationStateSnapshot *appStartupState = blockThis->getAppStartupInstrumentationState_();
            if (appStartupState.isInProgress && !appStartupState.hasFirstView) {
                return appStartupState.uiInitSpan;
            }
        }
        return nil;
    };
    callbacks.isViewLoadInProgress = ^BOOL() {
        return blockThis->spanStackingHandler_->hasSpanWithAttribute(@"bugsnag.span.category", @"view_load");
    };
    
    auto onViewLoadSpanStarted = ^(NSString * _Nonnull className) {
        if (onViewLoadSpanStarted_ != nil) {
            onViewLoadSpanStarted_(className);
        }
    };
    
    callbacks.onViewLoadSpanStarted = onViewLoadSpanStarted;
    
    return callbacks;
}

void
Tracer::createFrozenFrameSpan(NSTimeInterval startTime,
                              NSTimeInterval endTime,
                              BugsnagPerformanceSpanContext *parentContext) noexcept {
    SpanOptions options;
    options.startTime = startTime;
    options.parentContext = parentContext;
    options.makeCurrentContext = false;
    auto span = startSpan(@"FrozenFrame", options, BSGTriStateNo, @[]);
    [span endWithAbsoluteTime:endTime];
}

bool
Tracer::shouldInstrumentRendering(BugsnagPerformanceSpan *span) noexcept {
    switch (span.metricsOptions.rendering) {
        case BSGTriStateYes:
            return enabledMetrics_.rendering;
        case BSGTriStateNo:
            return false;
        case BSGTriStateUnset:
            return enabledMetrics_.rendering &&
            !span.wasStartOrEndTimeProvided &&
            span.firstClass == BSGTriStateYes;
    }
}
