//
//  Tracer.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import <BugsnagPerformance/BugsnagPerformanceViewType.h>
#import <memory>

namespace bugsnag {
// https://opentelemetry.io/docs/reference/specification/trace/api/#tracer
class Tracer {
public:
    Tracer() noexcept;
    
    void start(BugsnagPerformanceConfiguration *configuration) noexcept;
    
    std::unique_ptr<class Span> startSpan(NSString *name, CFAbsoluteTime startTime) noexcept;
    
    std::unique_ptr<class Span> startViewLoadedSpan(BugsnagPerformanceViewType viewType,
                                                    NSString *className,
                                                    CFAbsoluteTime startTime) noexcept;
    
    void reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept;

private:
    std::shared_ptr<class Sampler> sampler_;
    std::shared_ptr<class SpanProcessor> spanProcessor_;
    std::unique_ptr<class AppStartupInstrumentation> appStartupInstrumentation_;
    std::unique_ptr<class ViewLoadInstrumentation> viewLoadInstrumentation_;
    std::unique_ptr<class NetworkInstrumentation> networkInstrumentation_;
};
}
