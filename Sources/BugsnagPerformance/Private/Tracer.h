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

#import <memory>

namespace bugsnag {
// https://opentelemetry.io/docs/reference/specification/trace/api/#tracer

/**
 * Tracer starts all spans, then samples them and routes them to the batch when they end.
 */
class Tracer {
public:
    Tracer(std::shared_ptr<Sampler> sampler, std::shared_ptr<Batch> batch) noexcept;
    
    void start(BugsnagPerformanceConfiguration *configuration) noexcept;
    
    std::unique_ptr<class Span> startSpan(NSString *name, CFAbsoluteTime startTime) noexcept;
    
    std::unique_ptr<class Span> startViewLoadedSpan(BugsnagPerformanceViewType viewType,
                                                    NSString *className,
                                                    CFAbsoluteTime startTime) noexcept;
    
    void reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept;
    
private:
    std::shared_ptr<Sampler> sampler_;
    std::unique_ptr<class AppStartupInstrumentation> appStartupInstrumentation_;
    std::unique_ptr<class ViewLoadInstrumentation> viewLoadInstrumentation_;
    std::unique_ptr<class NetworkInstrumentation> networkInstrumentation_;
    
    std::shared_ptr<Batch> batch_;
    
    void tryAddSpanToBatch(std::unique_ptr<SpanData> spanData);
};
}
