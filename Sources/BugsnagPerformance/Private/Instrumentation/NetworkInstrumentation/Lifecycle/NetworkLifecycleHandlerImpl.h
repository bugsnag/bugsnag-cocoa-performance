//
//  NetworkLifecycleHandlerImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NetworkLifecycleHandler.h"
#import "NetworkEarlyPhaseHandler.h"
#import "../../../SpanAttributesProvider.h"
#import "../State/NetworkInstrumentationStateRepository.h"

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

class NetworkLifecycleHandlerImpl: public NetworkLifecycleHandler {
public:
    NetworkLifecycleHandlerImpl(std::shared_ptr<NetworkEarlyPhaseHandler> earlyPhaseHandler,
                                std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                                std::shared_ptr<NetworkInstrumentationStateRepository> repository) noexcept
    : earlyPhaseHandler_(earlyPhaseHandler)
    , spanAttributesProvider_(spanAttributesProvider)
    , repository_(repository) {}
    
    void onInstrumentationConfigured(bool isEnabled, BugsnagPerformanceNetworkRequestCallback callback) noexcept;
    
private:
    std::shared_ptr<NetworkEarlyPhaseHandler> earlyPhaseHandler_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    std::shared_ptr<NetworkInstrumentationStateRepository> repository_;
    
    void updateStateInfo(NetworkInstrumentationState *state,
                         BugsnagPerformanceNetworkRequestCallback callback);
    
    bool didVetoTracing(NSURL * _Nullable originalUrl,
                        BugsnagPerformanceNetworkRequestInfo * _Nullable info) noexcept;
    
    NetworkLifecycleHandlerImpl() = delete;
};
}

NS_ASSUME_NONNULL_END
