//
//  NetworkInstrumentation.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 14.10.22.
//

#import <Foundation/Foundation.h>
#import "../../Tracer.h"
#import "../../PhasedStartup.h"
#import "../../Sampler.h"
#import "../../NetworkHeaderInjector.h"
#import "State/NetworkInstrumentationStateRepository.h"
#import "System/BSGURLSessionPerformanceDelegate.h"
#import "NSURLSessionTask+Instrumentation.h"
#import "NetworkCommon.h"

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {
class Tracer;

class NetworkInstrumentation: public PhasedStartup {
public:
    NetworkInstrumentation(std::shared_ptr<Tracer> tracer,
                           std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                           std::shared_ptr<NetworkHeaderInjector> networkHeaderInjector,
                           std::shared_ptr<NetworkInstrumentationStateRepository> repository) noexcept
    : isEnabled_(true)
    , isEarlySpansPhase_(true)
    , tracer_(tracer)
    , spanAttributesProvider_(spanAttributesProvider)
    , networkHeaderInjector_(networkHeaderInjector)
    , repository_(repository)
    , earlySpans_([NSMutableArray new])
    , delegate_([[BSGURLSessionPerformanceDelegate alloc] initWithTracer:tracer_
                                                  spanAttributesProvider:spanAttributesProvider_
                                                              repository:repository])
    , checkIsEnabled_(^() { return isEnabled_; })
    , onSessionTaskResume_(^(NSURLSessionTask *task) { NSURLSessionTask_resume(task); })
    {}
    
    virtual ~NetworkInstrumentation() {}

    void earlyConfigure(BSGEarlyConfiguration *config) noexcept;
    void earlySetup() noexcept;
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept;
    void start() noexcept;

private:
    void markEarlySpan(BugsnagPerformanceSpan *span) noexcept;
    void endEarlySpansPhase() noexcept;
    void NSURLSessionTask_resume(NSURLSessionTask *task) noexcept;
    bool canTraceTask(NSURLSessionTask *task) noexcept;

    bool isEnabled_{true};
    std::shared_ptr<Tracer> tracer_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    std::shared_ptr<NetworkInstrumentationStateRepository> repository_;
    BSGURLSessionPerformanceDelegate * _Nullable delegate_;
    BSGSessionTaskResumeCallback onSessionTaskResume_;
    BSGIsEnabledCallback checkIsEnabled_;
    std::atomic<bool> isEarlySpansPhase_{true};
    std::mutex earlySpansMutex_;
    NSMutableArray<BugsnagPerformanceSpan *> * _Nullable earlySpans_;
    NSSet<NSRegularExpression *> * _Nullable propagateTraceParentToUrlsMatching_;
    std::shared_ptr<NetworkHeaderInjector> networkHeaderInjector_;
    BugsnagPerformanceNetworkRequestCallback networkRequestCallback_{nil};
};
}

NS_ASSUME_NONNULL_END
