//
//  ViewLoadLoadingIndicatorsHandlerImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 28/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadLoadingIndicatorsHandler.h"
#import "../State/ViewLoadInstrumentationStateRepository.h"
#import <mutex>

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

class ViewLoadLoadingIndicatorsHandlerImpl: public ViewLoadLoadingIndicatorsHandler {
public:
    ViewLoadLoadingIndicatorsHandlerImpl(std::shared_ptr<ViewLoadInstrumentationStateRepository> repository) noexcept
    : repository_(repository) {}
    
    void onLoadingIndicatorWasAdded(BugsnagPerformanceLoadingIndicatorView *loadingIndicator) noexcept;
    void onViewControllerUpdatedView(UIViewController *viewController) noexcept;
    
private:
    std::shared_ptr<ViewLoadInstrumentationStateRepository> repository_;
    std::mutex mutex_;
    
    void updateIndicatorsConditions(BugsnagPerformanceLoadingIndicatorView *loadingIndicator,
                                    NSArray<BugsnagPerformanceSpanCondition *> *conditions) noexcept;
    NSArray<BugsnagPerformanceSpanCondition *> *createConditions(BugsnagPerformanceLoadingIndicatorView *loadingIndicator) noexcept;
    void searchForLoadingIndicators(UIView *view) noexcept;
    
    ViewLoadLoadingIndicatorsHandlerImpl() = delete;
};
}

NS_ASSUME_NONNULL_END
