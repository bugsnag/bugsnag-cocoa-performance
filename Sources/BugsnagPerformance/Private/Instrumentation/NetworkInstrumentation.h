//
//  NetworkInstrumentation.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 14.10.22.
//

#import <Foundation/Foundation.h>
#import "../Tracer.h"
#import "../PhasedStartup.h"
#import "../Sampler.h"
#import "NetworkInstrumentation/NSURLSessionTask+Instrumentation.h"
#import "NetworkInstrumentation/NetworkCommon.h"

NS_ASSUME_NONNULL_BEGIN

@interface BSGURLSessionPerformanceDelegate : NSObject
@end

namespace bugsnag {
class Tracer;

class NetworkInstrumentation: public PhasedStartup {
public:
    NetworkInstrumentation(std::shared_ptr<Tracer> tracer,
                           std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                           std::shared_ptr<SpanStackingHandler> spanStackingHandler,
                           std::shared_ptr<Sampler> sampler) noexcept;
    virtual ~NetworkInstrumentation() {}

    void earlyConfigure(BSGEarlyConfiguration *config) noexcept;
    void earlySetup() noexcept;
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void start() noexcept;

private:
    void markEarlySpan(BugsnagPerformanceSpan *span) noexcept;
    void endEarlySpansPhase() noexcept;
    BOOL shouldAddTracePropagationHeaders(NSURL *url) noexcept;
    NSString *generateTraceParent(BugsnagPerformanceSpan * _Nullable span) noexcept;
    void injectHeaders(NSURLSessionTask *task, BugsnagPerformanceSpan * _Nullable span);
    void NSURLSessionTask_resume(NSURLSessionTask *task) noexcept;

    bool isEnabled_{true};
    std::shared_ptr<Tracer> tracer_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    BSGURLSessionPerformanceDelegate * _Nullable delegate_;
    BSGSessionTaskResumeCallback onSessionTaskResume_;
    BSGIsEnabledCallback checkIsEnabled_;
    std::atomic<bool> isEarlySpansPhase_{true};
    std::mutex earlySpansMutex_;
    NSMutableArray<BugsnagPerformanceSpan *> * _Nullable earlySpans_;
    NSSet<NSRegularExpression *> * _Nullable propagateTraceParentToUrlsMatching_;
    std::shared_ptr<Sampler> sampler_;
    std::shared_ptr<SpanStackingHandler> spanStackingHandler_;
    BugsnagPerformanceNetworkRequestCallback networkRequestCallback_;
};
}

NS_ASSUME_NONNULL_END
