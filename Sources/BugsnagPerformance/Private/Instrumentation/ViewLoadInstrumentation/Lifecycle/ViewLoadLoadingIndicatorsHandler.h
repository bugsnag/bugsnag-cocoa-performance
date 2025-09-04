//
//  ViewLoadLoadingIndicatorsHandler.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 28/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceLoadingIndicatorView.h>

typedef BugsnagPerformanceSpanCondition *_Nullable(^ ViewLoadLoadingIndicatorsHandlerOnLoadingCallback)(UIViewController *_Nonnull viewController);

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

class ViewLoadLoadingIndicatorsHandler {
public:
    virtual void onLoadingIndicatorWasAdded(BugsnagPerformanceLoadingIndicatorView *loadingIndicator) noexcept = 0;
    virtual void onViewControllerUpdatedView(UIViewController *viewController) noexcept = 0;
    virtual void setOnLoadingCallback(ViewLoadLoadingIndicatorsHandlerOnLoadingCallback callback) noexcept = 0;
    virtual ~ViewLoadLoadingIndicatorsHandler() {}
};
}

NS_ASSUME_NONNULL_END
