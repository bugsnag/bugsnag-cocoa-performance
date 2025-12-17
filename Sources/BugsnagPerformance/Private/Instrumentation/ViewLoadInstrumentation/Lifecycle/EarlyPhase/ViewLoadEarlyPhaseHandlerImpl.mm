//
//  ViewLoadEarlyPhaseHandlerImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 28/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadEarlyPhaseHandlerImpl.h"
#import "../../../../BugsnagPerformanceSpan+Private.h"

using namespace bugsnag;

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
            BSGLogDebug(@"[TEST] cancelling view load in reprocessing");
            [state.overallSpan cancel];
            [state.loadViewSpan cancel];
            [state.viewDidLoadSpan cancel];
            [state.viewWillAppearSpan cancel];
            [state.viewAppearingSpan cancel];
            [state.viewDidAppearSpan cancel];
            [state.viewWillLayoutSubviewsSpan cancel];
            [state.subviewLayoutSpan cancel];
            [state.viewDidLayoutSubviewsSpan cancel];
        }
    }
    [earlyStates_ removeAllObjects];
    isEarlyPhase_ = false;
}
