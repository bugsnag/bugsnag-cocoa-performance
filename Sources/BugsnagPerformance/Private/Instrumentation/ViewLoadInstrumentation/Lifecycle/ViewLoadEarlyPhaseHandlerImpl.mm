//
//  ViewLoadEarlyPhaseHandlerImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 28/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadEarlyPhaseHandlerImpl.h"

void
ViewLoadEarlyPhaseHandlerImpl::onNewStateCreated(ViewLoadInstrumentationState *state) noexcept {
    std::lock_guard<std::recursive_mutex> guard(mutex_);
    if (!isEarlyPhase_) {
        return;
    }
    [earlyStates_ addObject:state];
}

void
ViewLoadEarlyPhaseHandlerImpl::onEarlyPhaseEnded(bool isEnabled,
                                                 __nullable
                                                 BugsnagPerformanceViewControllerInstrumentationCallback callback) noexcept {
    std::lock_guard<std::recursive_mutex> guard(mutex_);
    if (!isEarlyPhase_) {
        return;
    }
    BugsnagPerformanceViewControllerInstrumentationCallback vcCheck = ^(UIViewController *viewController) {
        if (!isEnabled) {
            return NO;
        }
        if (callback != nil && viewController != nil) {
            return callback(viewController);
        }
        return YES;
    };
    for (ViewLoadInstrumentationState *state: earlyStates_) {
        UIViewController *viewController = state.viewController;
        if (!vcCheck(viewController)) {
            tracer_->cancelQueuedSpan(state.overallSpan);
            tracer_->cancelQueuedSpan(state.loadViewSpan);
            tracer_->cancelQueuedSpan(state.viewDidLoadSpan);
            tracer_->cancelQueuedSpan(state.viewWillAppearSpan);
            tracer_->cancelQueuedSpan(state.viewAppearingSpan);
            tracer_->cancelQueuedSpan(state.viewDidAppearSpan);
            tracer_->cancelQueuedSpan(state.viewWillLayoutSubviewsSpan);
            tracer_->cancelQueuedSpan(state.subviewLayoutSpan);
            tracer_->cancelQueuedSpan(state.viewDidLayoutSubviewsSpan);
        }
    }
    [earlyStates_ removeAllObjects];
    isEarlyPhase_ = false;
}
