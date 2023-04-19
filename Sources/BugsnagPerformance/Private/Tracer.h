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
#import "Configurable.h"
#import "SpanContextStack.h"

#import <memory>

namespace bugsnag {
// https://opentelemetry.io/docs/reference/specification/trace/api/#tracer

/**
 * Tracer starts all spans, then samples them and routes them to the batch when they end.
 */
class Tracer: public Configurable {
public:
    Tracer(SpanContextStack *spanContextStack,
           std::shared_ptr<Sampler> sampler,
           std::shared_ptr<Batch> batch,
           void (^onSpanStarted)()) noexcept;
    ~Tracer() {};

    void configure(BugsnagPerformanceConfiguration *configuration) noexcept;
    void setOnViewLoadSpanStarted(void (^onViewLoadSpanStarted)(NSString *className)) noexcept {
        onViewLoadSpanStarted_ = onViewLoadSpanStarted;
    }
    void start() noexcept;

    BugsnagPerformanceSpan *startAppStartSpan(NSString *name, SpanOptions options) noexcept;

    BugsnagPerformanceSpan *startCustomSpan(NSString *name, SpanOptions options) noexcept;

    BugsnagPerformanceSpan *startViewLoadSpan(BugsnagPerformanceViewType viewType,
                                              NSString *className,
                                              SpanOptions options) noexcept;

    void reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept;

    void cancelQueuedSpan(BugsnagPerformanceSpan *span) noexcept;

private:
    std::shared_ptr<Sampler> sampler_;
    std::unique_ptr<class ViewLoadInstrumentation> viewLoadInstrumentation_;
    std::unique_ptr<class NetworkInstrumentation> networkInstrumentation_;
    SpanContextStack *spanContextStack_;
    
    std::shared_ptr<Batch> batch_;
    void (^onSpanStarted_)(){nil};
    void (^onViewLoadSpanStarted_)(NSString *className){
        ^(NSString *) {}
    };

    BugsnagPerformanceConfiguration *configuration;
    
    BugsnagPerformanceSpan *startSpan(NSString *name, SpanOptions options, BSGFirstClass defaultFirstClass) noexcept;
    void tryAddSpanToBatch(std::shared_ptr<SpanData> spanData);
};
}
