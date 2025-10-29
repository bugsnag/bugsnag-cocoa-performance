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
    NSMutableArray<BugsnagPerformanceSpanCondition *> *newConditions = [NSMutableArray array];
    auto needsSpanUpdate = false;
    auto hasFoundFirstViewController = false;
    BugsnagPerformanceSpan *loadingIndicatorSpan;

    UIView *view = loadingIndicator;
    while (view != nil) {
        ViewLoadInstrumentationState *state = repository_->getInstrumentationState(view);
        __strong UIViewController *viewController = state.viewController;
        if (state != nil &&
            state.overallSpan.isValid &&
            viewController != nil) {
            
            if (callbacks_.onLoading) {
                BugsnagPerformanceSpanCondition *condition = callbacks_.onLoading(viewController);
                if (condition != nil) {
                    [newConditions addObject:condition];
                }
            }
            if (callbacks_.getParentContext &&
                !hasFoundFirstViewController &&
                loadingIndicator.name != nil) {
                BugsnagPerformanceSpanContext *parentContext = callbacks_.getParentContext(viewController);
                needsSpanUpdate = checkNeedsSpanUpdate(loadingIndicator, parentContext);
                if (parentContext && needsSpanUpdate) {
                    loadingIndicatorSpan = spanFactory_->startLoadingIndicatorSpan(loadingIndicator.name, parentContext);
                }
            }
            hasFoundFirstViewController = true;
        }
        view = view.superview;
    }
    
    auto state = [ViewLoadLoadingIndicatorState new];
    state.conditions = newConditions;
    state.loadingIndicatorSpan = loadingIndicatorSpan;
    state.needsSpanUpdate = needsSpanUpdate;
    return state;
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
    return !(loadingIndicator.loadingSpan.parentId == parentContext.spanId &&
             loadingIndicator.loadingSpan.traceId.hi == parentContext.traceId.hi &&
             loadingIndicator.loadingSpan.traceId.lo == parentContext.traceId.lo);
}
