//
//  ViewLoadLoadingIndicatorsHandlerImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 28/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadLoadingIndicatorsHandlerImpl.h"
#import "../../../BugsnagPerformanceLoadingIndicatorView+Private.h"

using namespace bugsnag;

void
ViewLoadLoadingIndicatorsHandlerImpl::onLoadingIndicatorWasAdded(BugsnagPerformanceLoadingIndicatorView *loadingIndicator) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (loadingIndicator == nil) {
        return;
    }
    
    auto newConditions = createConditions(loadingIndicator);
    updateIndicatorsConditions(loadingIndicator, newConditions);
}

void
ViewLoadLoadingIndicatorsHandlerImpl::onViewControllerUpdatedView(UIViewController *viewController) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    searchForLoadingIndicators(viewController.view);
}

#pragma mark Helpers

void
ViewLoadLoadingIndicatorsHandlerImpl::updateIndicatorsConditions(BugsnagPerformanceLoadingIndicatorView *loadingIndicator, NSArray<BugsnagPerformanceSpanCondition *> *conditions) noexcept {
    [loadingIndicator closeAllConditions];
    [loadingIndicator addConditions:conditions];
}

NSArray<BugsnagPerformanceSpanCondition *> *
ViewLoadLoadingIndicatorsHandlerImpl::createConditions(BugsnagPerformanceLoadingIndicatorView *loadingIndicator) noexcept {
    NSMutableArray<BugsnagPerformanceSpanCondition *> *newConditions = [NSMutableArray array];

    UIView *view = loadingIndicator;
    while (view != nil) {
        ViewLoadInstrumentationState *state = repository_->getInstrumentationState(view);
        __strong UIViewController *viewController = state.viewController;
        if (state != nil &&
            state.overallSpan.isValid &&
            viewController != nil) {
            
            if (onLoadingCallback) {
                BugsnagPerformanceSpanCondition *condition = onLoadingCallback(viewController);
                if (condition != nil) {
                    [newConditions addObject:condition];
                }
            }
        }
        view = view.superview;
    }
    return newConditions;
}

void
ViewLoadLoadingIndicatorsHandlerImpl::searchForLoadingIndicators(UIView *view) noexcept {
    if ([view isKindOfClass:[BugsnagPerformanceLoadingIndicatorView class]]) {
        auto loadingIndicator = (BugsnagPerformanceLoadingIndicatorView *)view;
        if (loadingIndicator.isLoading) {
            auto newConditions = createConditions(loadingIndicator);
            updateIndicatorsConditions(loadingIndicator, newConditions);
        }
    }
    for (UIView *subview in view.subviews) {
        searchForLoadingIndicators(subview);
    }
}
