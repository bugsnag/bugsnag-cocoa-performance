//
//  NetworkEarlyPhaseHandler.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import "../State/NetworkInstrumentationState.h"

typedef void (^NetworkEarlyPhaseHandlerStateCallback)(NetworkInstrumentationState * _Nonnull state);

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

class NetworkEarlyPhaseHandler {
public:
    virtual void onNewStateCreated(NetworkInstrumentationState *state) noexcept = 0;
    virtual void onEarlyPhaseEnded(bool isEnabled, NetworkEarlyPhaseHandlerStateCallback callback) noexcept = 0;
    virtual ~NetworkEarlyPhaseHandler() {}
};
}

NS_ASSUME_NONNULL_END
