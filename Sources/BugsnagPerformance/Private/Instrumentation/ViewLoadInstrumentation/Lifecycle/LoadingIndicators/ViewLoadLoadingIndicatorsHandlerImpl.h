//
//  ViewLoadLoadingIndicatorsHandlerImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 28/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "ViewLoadLoadingIndicatorsHandler.h"
#import "ViewLoadLoadingIndicatorState.h"
#import "../../State/ViewLoadInstrumentationStateRepository.h"
#import "../../../../Core/SpanFactory/ViewLoad/ViewLoadSpanFactory.h"
#import <mutex>

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

class ViewLoadLoadingIndicatorsHandlerImpl: public ViewLoadLoadingIndicatorsHandler {
public:
    ViewLoadLoadingIndicatorsHandlerImpl(std::shared_ptr<ViewLoadInstrumentationStateRepository> repository,
                                         std::shared_ptr<ViewLoadSpanFactory> spanFactory) noexcept
    : repository_(repository)
    , spanFactory_(spanFactory) {}
    
    void onLoadingIndicatorWasAdded(BugsnagPerformanceLoadingIndicatorView *loadingIndicator) noexcept;
    void onViewControllerUpdatedView(UIViewController *viewController) noexcept;
    void setCallbacks(ViewLoadLoadingIndicatorsHandlerCallbacks *callbacks) noexcept {
        callbacks_ = callbacks;
    }
    
private:
    std::shared_ptr<ViewLoadInstrumentationStateRepository> repository_;
    std::shared_ptr<ViewLoadSpanFactory> spanFactory_;
    std::mutex mutex_;
    ViewLoadLoadingIndicatorsHandlerCallbacks *callbacks_{nullptr};
    
    void updateIndicatorsState(BugsnagPerformanceLoadingIndicatorView *loadingIndicator, ViewLoadLoadingIndicatorState *state) noexcept;
    ViewLoadLoadingIndicatorState *newState(BugsnagPerformanceLoadingIndicatorView *loadingIndicator) noexcept;
    void updateLoadingIndicators(UIView *view) noexcept;
    bool checkNeedsSpanUpdate(BugsnagPerformanceLoadingIndicatorView *loadingIndicator,
                              BugsnagPerformanceSpanContext *parentContext) noexcept;
    
    ViewLoadLoadingIndicatorsHandlerImpl() = delete;
};
}

NS_ASSUME_NONNULL_END
