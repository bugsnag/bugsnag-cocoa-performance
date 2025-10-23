//
//  SpanLifecycleHandlerImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 09/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "SpanLifecycleHandlerImpl.h"
#import "../Span/BugsnagPerformanceSpan+Private.h"

using namespace bugsnag;


void
SpanLifecycleHandlerImpl::preStartSetup() noexcept {
    pipeline_->processPendingSpansIfNeeded();
}

void
SpanLifecycleHandlerImpl::onSpanStarted(BugsnagPerformanceSpan *span, const SpanOptions &options) noexcept {
    if (shouldInstrumentRendering(span) && getCurrentSnapshot_) {
        span.startFramerateSnapshot = getCurrentSnapshot_();
    }
    store_->addNewSpan(span, options.makeCurrentContext);
    callOnSpanStartCallbacks(span);
}

void
SpanLifecycleHandlerImpl::onSpanEndSet(BugsnagPerformanceSpan *span) noexcept {
    if (shouldInstrumentRendering(span) && getCurrentSnapshot_) {
        span.endFramerateSnapshot = getCurrentSnapshot_();
    }
}

void
SpanLifecycleHandlerImpl::onSpanClosed(BugsnagPerformanceSpan *span) noexcept {
    if (!span.isBlocked) {
        store_->removeSpan(span);
        pipeline_->addSpanForProcessing(span);
    }
}

BugsnagPerformanceSpanCondition *
SpanLifecycleHandlerImpl::onSpanBlocked(BugsnagPerformanceSpan *span, NSTimeInterval timeout) noexcept {
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
        this->conditionTimeoutExecutor_->cancelTimeout(c);
        
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
            this->store_->removeSpanFromBlocked(span);
            this->conditionTimeoutExecutor_->cancelTimeout(c);
            this->onSpanClosed(strongSpan);
        }
    }];
    conditionTimeoutExecutor_->scheduleTimeout(condition, timeout);
    store_->addSpanToBlocked(span);
    return condition;
}

void
SpanLifecycleHandlerImpl::onSpanCancelled(BugsnagPerformanceSpan *span) noexcept {
    if (!span) {
        return;
    }
    pipeline_->removeSpan(span);
    if (span.isBlocked) {
        store_->removeSpanFromBlocked(span);
    }
}

void
SpanLifecycleHandlerImpl::onAppEnteredBackground() noexcept {
    if (isStarted_) {
        abortAllOpenSpans();
    }
}

#pragma mark Private

void
SpanLifecycleHandlerImpl::callOnSpanStartCallbacks(BugsnagPerformanceSpan *span) noexcept {
    if(span == nil) {
        return;
    }

    for (BugsnagPerformanceSpanStartCallback callback: [onSpanStartCallbacks_ objects]) {
        @try {
            callback(span);
        } @catch(NSException *e) {
            BSGLogError(@"SpanLifecycleHandlerImpl::callOnSpanStartCallbacks: span onStart callback threw exception: %@", e);
        }
    }
}

void
SpanLifecycleHandlerImpl::abortAllOpenSpans() noexcept {
    store_->performActionAndClearOpenSpans(^(BugsnagPerformanceSpan *span) {
        [span abortIfOpen];
    });
}

bool
SpanLifecycleHandlerImpl::shouldInstrumentRendering(BugsnagPerformanceSpan *span) noexcept {
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
