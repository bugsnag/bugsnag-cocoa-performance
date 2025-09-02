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
#import "System/NetworkInstrumentationSystemUtils.h"
#import "System/NetworkSwizzlingHandler.h"
#import "Lifecycle/NetworkLifecycleHandler.h"

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {
class Tracer;

class NetworkInstrumentation: public PhasedStartup {
public:
    NetworkInstrumentation(std::shared_ptr<Tracer> tracer,
                           std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                           std::shared_ptr<NetworkHeaderInjector> networkHeaderInjector,
                           std::shared_ptr<NetworkInstrumentationStateRepository> repository,
                           std::shared_ptr<NetworkInstrumentationSystemUtils> systemUtils,
                           std::shared_ptr<NetworkSwizzlingHandler> swizzlingHandler,
                           std::shared_ptr<NetworkLifecycleHandler> lifecycleHandler,
                           BSGURLSessionPerformanceDelegate *delegate) noexcept
    : tracer_(tracer)
    , spanAttributesProvider_(spanAttributesProvider)
    , networkHeaderInjector_(networkHeaderInjector)
    , repository_(repository)
    , systemUtils_(systemUtils)
    , swizzlingHandler_(swizzlingHandler)
    , lifecycleHandler_(lifecycleHandler)
    , delegate_(delegate)
    , isEnabled_(true)
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
    void NSURLSessionTask_resume(NSURLSessionTask *task) noexcept;
    bool canTraceTask(NSURLSessionTask *task) noexcept;

    bool isEnabled_{true};
    std::shared_ptr<Tracer> tracer_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    std::shared_ptr<NetworkInstrumentationStateRepository> repository_;
    std::shared_ptr<NetworkInstrumentationSystemUtils> systemUtils_;
    std::shared_ptr<NetworkSwizzlingHandler> swizzlingHandler_;
    std::shared_ptr<NetworkLifecycleHandler> lifecycleHandler_;
    BSGURLSessionPerformanceDelegate * _Nullable delegate_;
    BSGSessionTaskResumeCallback onSessionTaskResume_;
    BSGIsEnabledCallback checkIsEnabled_;
    NSSet<NSRegularExpression *> * _Nullable propagateTraceParentToUrlsMatching_;
    std::shared_ptr<NetworkHeaderInjector> networkHeaderInjector_;
    BugsnagPerformanceNetworkRequestCallback networkRequestCallback_{nil};
};
}

NS_ASSUME_NONNULL_END
