//
//  ViewLoadLifecycleHandlerImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 21/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadLifecycleHandlerImpl.h"

#import "../../../BugsnagSwiftTools.h"

using namespace bugsnag;

static constexpr CGFloat kViewWillAppearPreloadedDelayThreshold = 1.0;
static constexpr CGFloat kLoadingBlockTimeout = 0.5;

#pragma mark Lifecycle

void
ViewLoadLifecycleHandlerImpl::onInstrumentationConfigured(bool isEnabled, __nullable BugsnagPerformanceViewControllerInstrumentationCallback callback) noexcept {
    earlyPhaseHandler_->onEarlyPhaseEnded(isEnabled, callback);
}

void
ViewLoadLifecycleHandlerImpl::onLoadView(UIViewController *viewController,
                                         ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept {
    auto state = repository_->getInstrumentationState(viewController);
    if (state == nil) {
        state = [ViewLoadInstrumentationState new];
        state.viewController = viewController;
        repository_->setInstrumentationState(viewController, state);
    }
    if (state.loadViewSpan != nil) {
        originalImplementation();
        return;
    }
    
    earlyPhaseHandler_->onNewStateCreated(state);
    state.overallSpan = spanFactory_->startOverallViewLoadSpan(viewController);
    
    state.loadViewSpan = spanFactory_->startLoadViewSpan(viewController,
                                                         state.overallSpan);
    originalImplementation();
    [state.loadViewSpan end];
    updateViewIfNeeded(state, viewController);
}

void
ViewLoadLifecycleHandlerImpl::onViewDidLoad(UIViewController *viewController,
                                            ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept {
    auto state = repository_->getInstrumentationState(viewController);
    if (state.overallSpan == nil || state.viewDidLoadSpan != nil) {
        originalImplementation();
        return;
    }
    
    state.viewDidLoadSpan = spanFactory_->startViewDidLoadSpan(viewController,
                                                               state.overallSpan);
    originalImplementation();
    [state.viewDidLoadSpan end];
    updateViewIfNeeded(state, viewController);
}

void
ViewLoadLifecycleHandlerImpl::onViewWillAppear(UIViewController *viewController,
                                               ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept {
    auto state = repository_->getInstrumentationState(viewController);
    BugsnagPerformanceSpan *overallSpan = state.overallSpan;
    if (overallSpan == nil || state.viewWillAppearSpan != nil) {
        originalImplementation();
        return;
    }
    [overallSpan forceMutate:^{
        adjustSpanIfPreloaded(overallSpan, state, [NSDate new], viewController);
    }];
    state.viewWillAppearSpan = spanFactory_->startViewWillAppearSpan(viewController,
                                                                     state.overallSpan);
    originalImplementation();
    [state.viewWillAppearSpan end];
    updateViewIfNeeded(state, viewController);
    state.viewAppearingSpan = spanFactory_->startViewAppearingSpan(viewController,
                                                                   state.overallSpan);
}

void
ViewLoadLifecycleHandlerImpl::onViewDidAppear(UIViewController *viewController,
                                              ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept {
    auto state = repository_->getInstrumentationState(viewController);
    if (state.overallSpan == nil || state.viewDidAppearSpan != nil || state.isHandlingViewDidAppear) {
        originalImplementation();
        return;
    }
    state.isHandlingViewDidAppear = YES;
    endViewAppearingSpan(state, CFAbsoluteTimeGetCurrent());
    state.viewDidAppearSpan = spanFactory_->startViewDidAppearSpan(viewController,
                                                                   state.overallSpan);
    originalImplementation();
    [state.viewDidAppearSpan end];
    state.hasAppeared = true;
    updateViewIfNeeded(state, viewController);
    loadingIndicatorsHandler_->onViewControllerDidAppear(viewController);
    endOverallSpan(state, viewController, CFAbsoluteTimeGetCurrent());
    state.isHandlingViewDidAppear = NO;
}

void
ViewLoadLifecycleHandlerImpl::onViewWillLayoutSubviews(UIViewController *viewController,
                                                       ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept {
    auto state = repository_->getInstrumentationState(viewController);
    if (state.overallSpan == nil || state.viewWillLayoutSubviewsSpan != nil) {
        originalImplementation();
        return;
    }
    state.viewWillLayoutSubviewsSpan = spanFactory_->startViewWillLayoutSubviewsSpan(viewController,
                                                                                     state.overallSpan);
    originalImplementation();
    [state.viewWillLayoutSubviewsSpan end];
    updateViewIfNeeded(state, viewController);
    state.subviewLayoutSpan = spanFactory_->startSubviewsLayoutSpan(viewController,
                                                                    state.overallSpan);
}

void
ViewLoadLifecycleHandlerImpl::onViewDidLayoutSubviews(UIViewController *viewController,
                                                      ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept {
    auto state = repository_->getInstrumentationState(viewController);
    if (state.overallSpan == nil || state.viewDidLayoutSubviewsSpan != nil) {
        originalImplementation();
        return;
    }
    endSubviewsLayoutSpan(state);
    state.viewDidLayoutSubviewsSpan = spanFactory_->startViewDidLayoutSubviewsSpan(viewController,
                                                                                   state.overallSpan);
    originalImplementation();
    [state.viewDidLayoutSubviewsSpan end];
    updateViewIfNeeded(state, viewController);
    auto subviewsDidLayoutAtTime = CFAbsoluteTimeGetCurrent();
    
    __block __weak UIViewController *weakViewController = viewController;
    void (^endViewAppearingSpanIfNeeded)(ViewLoadInstrumentationState *) = ^void(ViewLoadInstrumentationState *s) {
        __strong UIViewController *strongViewController = weakViewController;
        auto overallSpan = s.overallSpan;
        if (overallSpan.state == SpanStateOpen) {
            endOverallSpan(s, strongViewController, subviewsDidLayoutAtTime);
        }
        endViewAppearingSpan(s, subviewsDidLayoutAtTime);
    };
    
    // If the overall span still hasn't ended when the ViewController is deallocated, use the time from viewDidLayoutSubviews
    state.onDealloc = endViewAppearingSpanIfNeeded;
    
    __block __weak ViewLoadInstrumentationState *weakState = state;
    // If the overall span still hasn't ended after 10 seconds, use the time from viewDidLayoutSubviews
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong UIViewController *strongViewController = weakViewController;
        __strong ViewLoadInstrumentationState *strongState = weakState;
        if (strongViewController == nil || strongState == nil) {
            return;
        }
        strongState.onDealloc = nil;
        endViewAppearingSpanIfNeeded(strongState);
    });
}

void
ViewLoadLifecycleHandlerImpl::onViewWillDisappear(UIViewController *viewController,
                                                  ViewLoadSwizzlingOriginalImplementationCallback originalImplementation,
                                                  SpanLifecycleCallback onSpanCancelled) noexcept {
    auto state = repository_->getInstrumentationState(viewController);
    if (!(state.overallSpan.isValid || state.overallSpan.isBlocked)) {
        originalImplementation();
        return;
    }
    
    BugsnagPerformanceSpan *overallSpan = state.overallSpan;
    if (overallSpan != nil) {
        [state.overallSpan cancel];
        if (onSpanCancelled) {
            onSpanCancelled(overallSpan);
        }
    }
    
    [state.loadViewSpan cancel];
    [state.viewDidLoadSpan cancel];
    [state.viewWillAppearSpan cancel];
    [state.viewAppearingSpan cancel];
    [state.viewDidAppearSpan cancel];
    [state.viewWillLayoutSubviewsSpan cancel];
    [state.subviewLayoutSpan cancel];
    [state.viewDidLayoutSubviewsSpan cancel];
    [state.loadingPhaseSpan cancel];
    state.overallSpan = nil;
    originalImplementation();
}

void
ViewLoadLifecycleHandlerImpl::onLoadingIndicatorWasAdded(BugsnagPerformanceLoadingIndicatorView *loadingIndicator) noexcept {
    if (loadingIndicator == nil) {
        return;
    }
    loadingIndicatorsHandler_->onLoadingIndicatorWasAdded(loadingIndicator);
}

#pragma mark Helpers

void
ViewLoadLifecycleHandlerImpl::endOverallSpan(ViewLoadInstrumentationState *state, UIViewController *viewController, CFAbsoluteTime atTime) noexcept {
    std::lock_guard<std::mutex> guard(spanMutex_);
    if (state.overallSpan == nil || !state.overallSpan.isValid) {
        return;
    }
    BugsnagPerformanceSpan *overallSpan = state.overallSpan;
    [crosstalkAPI_ willEndViewLoadSpan:overallSpan viewController:viewController];
    
    if (state.loadingPhaseSpan == nil) {
        [state.overallSpan blockWithTimeout:kLoadingBlockTimeout];
    }

    [state.overallSpan endWithAbsoluteTime:atTime];
}

void
ViewLoadLifecycleHandlerImpl::endViewAppearingSpan(ViewLoadInstrumentationState *state, CFAbsoluteTime atTime) noexcept {
    std::lock_guard<std::mutex> guard(spanMutex_);
    if (!state.viewAppearingSpan.isValid) {
        return;
    }
    [state.viewAppearingSpan endWithAbsoluteTime:atTime];
}

void
ViewLoadLifecycleHandlerImpl::endSubviewsLayoutSpan(ViewLoadInstrumentationState *state) noexcept {
    std::lock_guard<std::mutex> guard(spanMutex_);
    if (!state.subviewLayoutSpan.isValid) {
        return;
    }
    [state.subviewLayoutSpan end];
}

void
ViewLoadLifecycleHandlerImpl::adjustSpanIfPreloaded(BugsnagPerformanceSpan *span, ViewLoadInstrumentationState *state, NSDate *viewWillAppearStartTime, UIViewController *viewController) noexcept {
    NSDate *viewDidLoadEndTime = [state.viewDidLoadSpan endTime];
    if (state.isMarkedAsPreloaded || viewDidLoadEndTime == nil) {
        return;
    }
    auto isPreloaded = [viewWillAppearStartTime timeIntervalSinceDate: viewDidLoadEndTime] > kViewWillAppearPreloadedDelayThreshold;
    if (isPreloaded) {
        auto viewType = BugsnagPerformanceViewTypeUIKit;
        auto className = [BugsnagSwiftTools demangledClassNameFromInstance:viewController];
        [span updateName: [NSString stringWithFormat:@"%@ (pre-load)", span.name]];
        [span internalSetMultipleAttributes:spanAttributesProvider_->preloadViewLoadSpanAttributes(className, viewType)];
        state.isMarkedAsPreloaded = true;
        [span endWithEndTime:viewDidLoadEndTime];
        
        state.overallSpan = spanFactory_->startPreloadedPresentingSpan(viewController);
    }
}

void
ViewLoadLifecycleHandlerImpl::updateViewIfNeeded(ViewLoadInstrumentationState *state, UIViewController *viewController) noexcept {
    if (state == nil || viewController == nil) {
        return;
    }

    UIView *currentView = state.view;
    if (currentView != viewController.view) {
        if (currentView != nil) {
            repository_->setInstrumentationState(currentView, nil);
        }

        state.view = viewController.view;
        repository_->setInstrumentationState(viewController.view, state);
        loadingIndicatorsHandler_->onViewControllerUpdatedView(viewController);
    }
}

BugsnagPerformanceSpanCondition *
ViewLoadLifecycleHandlerImpl::onLoadingStarted(UIViewController *viewController) noexcept {
    auto state = repository_->getInstrumentationState(viewController);
    if (state.overallSpan == nil) {
        return nil;
    }
    bool spanWasCreated = false;
    if (state.loadingPhaseSpan == nil) {
        BugsnagPerformanceSpanCondition *condition = [state.overallSpan blockWithTimeout:kLoadingBlockTimeout];
        [condition upgrade];

        state.loadingPhaseSpan = spanFactory_->startLoadingSpan(viewController,
                                                                state.overallSpan,
                                                                @[condition]);
        spanWasCreated = true;
    }
    auto loadingCondition = [state.loadingPhaseSpan blockWithTimeout:kLoadingBlockTimeout];
    [loadingCondition upgrade];
    if (spanWasCreated) {
        [state.loadingPhaseSpan end];
    }
    return loadingCondition;
}
