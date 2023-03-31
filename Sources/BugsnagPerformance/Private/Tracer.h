//
//  Tracer.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import <BugsnagPerformance/BugsnagPerformanceViewType.h>
#import "Instrumentation/AppStartupInstrumentation.h"
#import "Instrumentation/NetworkInstrumentation.h"
#import "Instrumentation/ViewLoadInstrumentation.h"
#import "Span.h"
#import "Sampler.h"
#import "Batch.h"
#import "SpanOptions.h"

#import <memory>

namespace bugsnag {
// https://opentelemetry.io/docs/reference/specification/trace/api/#tracer

/**
 * Tracer starts all spans, then samples them and routes them to the batch when they end.
 */
class Tracer {
public:
    Tracer(std::shared_ptr<Sampler> sampler, std::shared_ptr<Batch> batch, void (^onSpanStarted)()) noexcept;

    void start(BugsnagPerformanceConfiguration *configuration) noexcept;

    BugsnagPerformanceSpan *startAppStartSpan(NSString *name, SpanOptions options) noexcept;

    BugsnagPerformanceSpan *startCustomSpan(NSString *name, SpanOptions options) noexcept;

    BugsnagPerformanceSpan *startViewLoadSpan(BugsnagPerformanceViewType viewType,
                                              NSString *className,
                                              SpanOptions options) noexcept;

    void reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept;

    void cancelQueuedSpan(BugsnagPerformanceSpan *span) noexcept;

private:
    std::shared_ptr<Sampler> sampler_;
    AppStartupInstrumentation *appStartupInstrumentation_;
    std::unique_ptr<class ViewLoadInstrumentation> viewLoadInstrumentation_;
    std::unique_ptr<class NetworkInstrumentation> networkInstrumentation_;
    
    std::shared_ptr<Batch> batch_;
    void (^onSpanStarted_)(){nil};
    
    BugsnagPerformanceSpan *startSpan(NSString *name, SpanOptions options, BSGFirstClass defaultFirstClass) noexcept;
    void tryAddSpanToBatch(std::shared_ptr<SpanData> spanData);
};
}
