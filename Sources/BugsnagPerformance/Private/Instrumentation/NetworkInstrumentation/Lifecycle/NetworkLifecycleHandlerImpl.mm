//
//  NetworkLifecycleHandlerImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NetworkLifecycleHandlerImpl.h"
#import "../../../BugsnagPerformanceSpan+Private.h"

using namespace bugsnag;

void
NetworkLifecycleHandlerImpl::onInstrumentationConfigured(bool isEnabled,
                                                         BugsnagPerformanceNetworkRequestCallback callback) noexcept {
    NetworkEarlyPhaseHandlerStateCallback stateCallback = ^(NetworkInstrumentationState *state) {
        updateStateInfo(state, callback);
    };
    earlyPhaseHandler_->onEarlyPhaseEnded(isEnabled, stateCallback);
}

#pragma mark Helpers

void
NetworkLifecycleHandlerImpl::updateStateInfo(NetworkInstrumentationState *state,
                                             BugsnagPerformanceNetworkRequestCallback callback) {
    auto info = [BugsnagPerformanceNetworkRequestInfo new];
    NSString *urlString = [state.overallSpan getAttribute:spanAttributesProvider_->httpUrlAttributeKey()];
    NSURL *originalUrl = [NSURL URLWithString:urlString];
    info.url = originalUrl;
    bool hasBeenVetoed = false;
    if (callback) {
        // We have to check again because the real callback might not have been set initially.
        info = callback(info);
        hasBeenVetoed = didVetoTracing(originalUrl, info);
    }
    state.url = info.url;
    state.hasBeenVetoed = hasBeenVetoed;
}

bool
NetworkLifecycleHandlerImpl::didVetoTracing(NSURL * _Nullable originalUrl,
                                            BugsnagPerformanceNetworkRequestInfo * _Nullable info) noexcept {
    // A user changing the request URL to nil signals a veto
    bool userVetoedTracing = originalUrl != nil && info.url == nil;
    if (userVetoedTracing) {
        BSGLogDebug(@"User vetoed tracing on %@", originalUrl);
        return true;
    }
    BSGLogTrace(@"User did not veto tracing on %@", originalUrl);
    return false;
}
