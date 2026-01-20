//
//  ViewLoadLoadingIndicatorsHandlerImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 28/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadLoadingIndicatorsHandlerImpl.h"
#import "../../../../BugsnagPerformanceLoadingIndicatorView+Private.h"
#import "../../../../BugsnagPerformanceSpan+Private.h"

using namespace bugsnag;

void
ViewLoadLoadingIndicatorsHandlerImpl::onLoadingIndicatorWasAdded(BugsnagPerformanceLoadingIndicatorView *loadingIndicator) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (loadingIndicator == nil) {
        return;
    }
    
    auto state = newState(loadingIndicator);
    updateIndicatorsState(loadingIndicator, state);
}

void
ViewLoadLoadingIndicatorsHandlerImpl::onViewControllerUpdatedView(UIViewController *viewController) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    updateLoadingIndicators(viewController.view);
}

void
ViewLoadLoadingIndicatorsHandlerImpl::onViewControllerDidAppear(UIViewController *viewController) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    updateLoadingIndicators(viewController.view);
}

#pragma mark Helpers

void
ViewLoadLoadingIndicatorsHandlerImpl::updateIndicatorsState(BugsnagPerformanceLoadingIndicatorView *loadingIndicator, ViewLoadLoadingIndicatorState *state) noexcept {
    [loadingIndicator closeAllConditions];
    [loadingIndicator addConditions:state.conditions];
    if (state.needsSpanUpdate) {
        [loadingIndicator endLoadingSpan];
        [loadingIndicator setLoadingSpan:state.loadingIndicatorSpan];
    }
}

ViewLoadLoadingIndicatorState *
ViewLoadLoadingIndicatorsHandlerImpl::newState(BugsnagPerformanceLoadingIndicatorView *loadingIndicator) noexcept {
    auto hasFoundFirstViewController = false;

    auto state = [ViewLoadLoadingIndicatorState new];
    UIView *view = loadingIndicator;
    while (view != nil) {
        ViewLoadInstrumentationState *viewLoadState = repository_->getInstrumentationState(view);
        if (viewLoadState.overallSpan.isValid && viewLoadState.viewController != nil) {
            addToState(state,
                       loadingIndicator,
                       viewLoadState,
                       !hasFoundFirstViewController);
            hasFoundFirstViewController = true;
        }
        
        view = view.superview;
    }
    
    return state;
}

void
ViewLoadLoadingIndicatorsHandlerImpl::addToState(ViewLoadLoadingIndicatorState *state,
                                                 BugsnagPerformanceLoadingIndicatorView *loadingIndicator,
                                                 ViewLoadInstrumentationState *viewLoadState,
                                                 BOOL isFirstViewController) noexcept {
    __strong UIViewController *viewController = viewLoadState.viewController;
    
    if (viewController == nil || !viewLoadState.hasAppeared) {
        return;
    }
    if (callbacks_.onLoading) {
        BugsnagPerformanceSpanCondition *condition = callbacks_.onLoading(viewController);
        if (condition != nil) {
            [state.conditions addObject:condition];
        }
    }
    if (callbacks_.getParentContext &&
        isFirstViewController &&
        loadingIndicator.name != nil) {
        BugsnagPerformanceSpanContext *parentContext = callbacks_.getParentContext(viewController);
        BOOL needsSpanUpdate = checkNeedsSpanUpdate(loadingIndicator, parentContext);
        if (parentContext && needsSpanUpdate) {
            state.needsSpanUpdate = needsSpanUpdate;
            state.loadingIndicatorSpan = spanFactory_->startLoadingIndicatorSpan(loadingIndicator.name, parentContext);
        }
    }
}

void
ViewLoadLoadingIndicatorsHandlerImpl::updateLoadingIndicators(UIView *view) noexcept {
    if ([view isKindOfClass:[BugsnagPerformanceLoadingIndicatorView class]]) {
        auto loadingIndicator = (BugsnagPerformanceLoadingIndicatorView *)view;
        if (loadingIndicator.isLoading) {
            auto state = newState(loadingIndicator);
            updateIndicatorsState(loadingIndicator, state);
        }
    }
    for (UIView *subview in view.subviews) {
        updateLoadingIndicators(subview);
    }
}

bool
ViewLoadLoadingIndicatorsHandlerImpl::checkNeedsSpanUpdate(BugsnagPerformanceLoadingIndicatorView *loadingIndicator,
                                                           BugsnagPerformanceSpanContext *parentContext) noexcept {
    return ![parentContext isParentOf:loadingIndicator.loadingSpan];
}
