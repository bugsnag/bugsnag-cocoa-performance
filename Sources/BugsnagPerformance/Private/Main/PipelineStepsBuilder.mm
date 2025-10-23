//
//  PipelineStepsBuilder.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "PipelineStepsBuilder.h"
#import "../Core/Span/BugsnagPerformanceSpan+Private.h"
#import "../Metrics/FrameMetrics/FrameMetricsSnapshot.h"

#define buildSyncStep(workBlock) \
    __block auto blockThis = this; \
    auto work = ^bool (BugsnagPerformanceSpan *span) { \
        workBlock \
    }; \
    return std::make_shared<SpanProcessingPipelineStep>(work)

using namespace bugsnag;

#pragma mark PhasedStartup

void
PipelineStepsBuilder::configure(BugsnagPerformanceConfiguration *config) noexcept {
    configuration_ = config;
    enabledMetrics_ = config.enabledMetrics;
}

#pragma mark Public

std::vector<std::shared_ptr<SpanProcessingPipelineStep>>
PipelineStepsBuilder::buildPreprocessSteps() noexcept {
    auto result = std::vector<std::shared_ptr<SpanProcessingPipelineStep>>();
    result.push_back(buildProcessConditionsStep());
    result.push_back(buildAddFrameMetricsStep());
    result.push_back(buildFilterOutSpansStep());
    result.push_back(buildRunEndCallbacksStep());
    return result;
}

std::vector<std::shared_ptr<SpanProcessingPipelineStep>>
PipelineStepsBuilder::buildMainFlowSteps() noexcept {
    auto result = std::vector<std::shared_ptr<SpanProcessingPipelineStep>>();
    result.push_back(buildAddSystemMetricsStep());
    result.push_back(buildFilterOutSpansStep());
    return result;
}

#pragma mark Common Steps

std::shared_ptr<SpanProcessingPipelineStep>
PipelineStepsBuilder::buildFilterOutSpansStep() noexcept {
    buildSyncStep(
        if(span.state == SpanStateAborted) {
            return false;
        }

        if (!blockThis->sampler_->sampled(span)) {
            [span abortUnconditionally];
            return false;
        }
        return true;
    );
}

#pragma mark Preprocess Steps

std::shared_ptr<SpanProcessingPipelineStep>
PipelineStepsBuilder::buildProcessConditionsStep() noexcept {
    buildSyncStep(
        blockThis->processSpanConditions(span);
        return true;
    );
}

std::shared_ptr<SpanProcessingPipelineStep>
PipelineStepsBuilder::buildAddFrameMetricsStep() noexcept {
    buildSyncStep(
        if (blockThis->shouldInstrumentRendering(span)) {
            blockThis->processFrameMetrics(span);
        }
        return true;
    );
}

std::shared_ptr<SpanProcessingPipelineStep>
PipelineStepsBuilder::buildRunEndCallbacksStep() noexcept {
    buildSyncStep(
        if (span != nil && span.state == SpanStateEnded) {
            blockThis->callOnSpanEndCallbacks(span);
            if (span.state == SpanStateAborted) {
                return false;
            }
        }
        return true;
    );
}

#pragma mark Main Flow Steps

std::shared_ptr<SpanProcessingPipelineStep>
PipelineStepsBuilder::buildAddSystemMetricsStep() noexcept {
    buildSyncStep(
      auto samples = blockThis->systemInfoSampler_->samplesAroundTimePeriod(span.actuallyStartedAt, span.actuallyEndedAt);
      if (samples.size() >= 2) {
          if (blockThis->shouldSampleCPU(span)) {
              [span forceMutate:^() {
                  [span internalSetMultipleAttributes:blockThis->spanAttributesProvider_->cpuSampleAttributes(samples)];
              }];
          }
          if (blockThis->shouldSampleMemory(span)) {
              [span forceMutate:^() {
                  [span internalSetMultipleAttributes:blockThis->spanAttributesProvider_->memorySampleAttributes(samples)];
              }];
          }
      }
      return true;
    );
}

#pragma mark Utility

bool
PipelineStepsBuilder::shouldSampleCPU(BugsnagPerformanceSpan *span) noexcept {
    if (span.metricsOptions.cpu == BSGTriStateUnset) {
        return span.firstClass == BSGTriStateYes;
    }
    return span.metricsOptions.cpu == BSGTriStateYes;
}

bool
PipelineStepsBuilder::shouldSampleMemory(BugsnagPerformanceSpan *span) noexcept {
    if (span.metricsOptions.memory == BSGTriStateUnset) {
        return span.firstClass == BSGTriStateYes;
    }
    return span.metricsOptions.memory == BSGTriStateYes;
}

bool
PipelineStepsBuilder::shouldInstrumentRendering(BugsnagPerformanceSpan *span) noexcept {
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

void
PipelineStepsBuilder::processFrameMetrics(BugsnagPerformanceSpan *span) noexcept {
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

void
PipelineStepsBuilder::createFrozenFrameSpan(NSTimeInterval startTime,
                                            NSTimeInterval endTime,
                                            BugsnagPerformanceSpanContext *parentContext) noexcept {
    SpanOptions options;
    options.startTime = startTime;
    options.parentContext = parentContext;
    options.makeCurrentContext = false;
    auto span = plainSpanFactory_->startSpan(@"FrozenFrame", options, BSGTriStateNo, @{}, @[]);
    [span endWithAbsoluteTime:endTime];
}

void
PipelineStepsBuilder::callOnSpanEndCallbacks(BugsnagPerformanceSpan *span) noexcept {
    if (span == nil) {
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

void
PipelineStepsBuilder::processSpanConditions(BugsnagPerformanceSpan *span) noexcept {
    @synchronized (span) {
        for (BugsnagPerformanceSpanCondition *condition in span.conditionsToEndOnClose) {
            [condition closeWithEndTime:span.endTime];
        }
    }
}
