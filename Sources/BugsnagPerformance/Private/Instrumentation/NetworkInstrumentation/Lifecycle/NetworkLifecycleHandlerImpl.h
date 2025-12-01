//
//  NetworkLifecycleHandlerImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NetworkLifecycleHandler.h"
#import "NetworkEarlyPhaseHandler.h"
#import "../../../Tracer.h"
#import "../State/NetworkInstrumentationStateRepository.h"
#import "../../../SpanFactory/Network/NetworkSpanFactory.h"
#import "../System/NetworkInstrumentationSystemUtils.h"
#import "../System/NetworkHeaderInjector.h"

namespace bugsnag {

class NetworkLifecycleHandlerImpl: public NetworkLifecycleHandler {
public:
    NetworkLifecycleHandlerImpl(std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                                std::shared_ptr<NetworkSpanFactory> spanFactory,
                                std::shared_ptr<NetworkEarlyPhaseHandler> earlyPhaseHandler,
                                std::shared_ptr<NetworkInstrumentationSystemUtils> systemUtils,
                                std::shared_ptr<NetworkInstrumentationStateRepository> repository,
                                std::shared_ptr<NetworkHeaderInjector> networkHeaderInjector) noexcept
    : spanAttributesProvider_(spanAttributesProvider)
    , spanFactory_(spanFactory)
    , earlyPhaseHandler_(earlyPhaseHandler)
    , systemUtils_(systemUtils)
    , repository_(repository)
    , networkHeaderInjector_(networkHeaderInjector) {}
    
    void onInstrumentationConfigured(bool isEnabled, BugsnagPerformanceNetworkRequestCallback callback) noexcept;
    void onTaskResume(NSURLSessionTask *task) noexcept;
    void onTaskDidFinishCollectingMetrics(NSURLSessionTask *task,
                                          NSURLSessionTaskMetrics *metrics,
                                          NSString *ignoreBaseEndpoint) noexcept;
    
private:
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    std::shared_ptr<NetworkSpanFactory> spanFactory_;
    std::shared_ptr<NetworkEarlyPhaseHandler> earlyPhaseHandler_;
    std::shared_ptr<NetworkInstrumentationSystemUtils> systemUtils_;
    std::shared_ptr<NetworkInstrumentationStateRepository> repository_;
    std::shared_ptr<NetworkHeaderInjector> networkHeaderInjector_;
    BugsnagPerformanceNetworkRequestCallback networkRequestCallback_{nil};
    
    void updateState(NetworkInstrumentationState *state);
    
    bool didVetoTracing(NSURL *originalUrl,
                        BugsnagPerformanceNetworkRequestInfo *info) noexcept;
    
    bool canTraceTask(NSURLSessionTask *task) noexcept;
    
    void reportInternalErrorSpan(NSString *httpMethod,
                                 NSError *error) noexcept;
    
    NetworkInstrumentationState *initializeStateAndSaveIfNotVetoed(NSURLSessionTask *task,
                                                                   NSString *httpMethod,
                                                                   NSURL *originalUrl,
                                                                   NSError *error) noexcept;
    
    void endSpanOnDestroyIfNeeded(NetworkInstrumentationState *state) noexcept;
    
    bool shouldRecordFinishedTask(NSURLSessionTask *task,
                                  NSString *ignoreBaseEndpoint,
                                  NSError **error) noexcept;
    
    NetworkLifecycleHandlerImpl() = delete;
};
}
