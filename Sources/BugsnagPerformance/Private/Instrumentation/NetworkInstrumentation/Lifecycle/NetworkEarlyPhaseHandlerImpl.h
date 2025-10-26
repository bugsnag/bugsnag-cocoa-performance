//
//  NetworkEarlyPhaseHandlerImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "NetworkEarlyPhaseHandler.h"
#import "../../../Core/Attributes/SpanAttributesProvider.h"

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

class NetworkEarlyPhaseHandlerImpl: public NetworkEarlyPhaseHandler {
public:
    NetworkEarlyPhaseHandlerImpl(std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) noexcept
    : spanAttributesProvider_(spanAttributesProvider)
    , isEarlyPhase_(true)
    , earlyStates_([NSMutableArray array]) {}
    
    void onNewStateCreated(NetworkInstrumentationState *state) noexcept;
    void onEarlyPhaseEnded(bool isEnabled, NetworkEarlyPhaseHandlerStateCallback callback) noexcept;
    
private:
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    
    std::mutex mutex_;
    std::atomic<bool> isEarlyPhase_{true};
    NSMutableArray<NetworkInstrumentationState *> * _Nullable earlyStates_;
    
    void cancelEarlyStatesOnPhaseEnd() noexcept;
    void updateEarlyStatesOnPhaseEnd(NetworkEarlyPhaseHandlerStateCallback callback) noexcept;
    
    NetworkEarlyPhaseHandlerImpl() = delete;
};
}

NS_ASSUME_NONNULL_END
