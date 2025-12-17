//
//  NetworkEarlyPhaseHandlerImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NetworkEarlyPhaseHandlerImpl.h"

using namespace bugsnag;

void
NetworkEarlyPhaseHandlerImpl::onNewStateCreated(NetworkInstrumentationState *state) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (!isEarlyPhase_) {
        return;
    }
    [earlyStates_ addObject:state];
}

void
NetworkEarlyPhaseHandlerImpl::onEarlyPhaseEnded(bool isEnabled,
                                                NetworkEarlyPhaseHandlerStateCallback callback) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (!isEnabled) {
        cancelEarlyStatesOnPhaseEnd();
    } else {
        updateEarlyStatesOnPhaseEnd(callback);
    }
    isEarlyPhase_ = false;
    [earlyStates_ removeAllObjects];
}

#pragma mark Helpers

void
NetworkEarlyPhaseHandlerImpl::cancelEarlyStatesOnPhaseEnd() noexcept {
    for (NetworkInstrumentationState *state: earlyStates_) {
        BSGLogDebug(@"[TEST] cancelling network span");
        [state.overallSpan cancel];
    }
}

void
NetworkEarlyPhaseHandlerImpl::updateEarlyStatesOnPhaseEnd(NetworkEarlyPhaseHandlerStateCallback callback) noexcept {
    for (NetworkInstrumentationState *state: earlyStates_) {
        callback(state);
        if (state.hasBeenVetoed) {
            [state.overallSpan cancel];
            continue;
        }
        [state.overallSpan forceMutate:^{
            [state.overallSpan internalSetMultipleAttributes:spanAttributesProvider_->networkSpanUrlAttributes(state.url, nil)];
        }];
    }
}
