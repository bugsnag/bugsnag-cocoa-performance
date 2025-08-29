//
//  ViewLoadLoadingIndicatorsHandler.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 28/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceLoadingIndicatorView.h>

NS_ASSUME_NONNULL_BEGIN

typedef BugsnagPerformanceSpanCondition *(^ ViewLoadLoadingIndicatorsHandlerOnLoadingCallback)(UIViewController *viewController);

namespace bugsnag {

class ViewLoadLoadingIndicatorsHandler {
public:
    virtual void onLoadingIndicatorWasAdded(BugsnagPerformanceLoadingIndicatorView *loadingIndicator) noexcept = 0;
    virtual void onViewControllerUpdatedView(UIViewController *viewController) noexcept = 0;
    ViewLoadLoadingIndicatorsHandlerOnLoadingCallback onLoadingCallback;
    virtual ~ViewLoadLoadingIndicatorsHandler() {}
};
}

NS_ASSUME_NONNULL_END
