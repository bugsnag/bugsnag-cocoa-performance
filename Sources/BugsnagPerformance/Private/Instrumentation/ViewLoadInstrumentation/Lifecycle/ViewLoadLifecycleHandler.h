//
//  ViewLoadLifecycleHandler.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 21/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import <BugsnagPerformance/BugsnagPerformanceLoadingIndicatorView.h>
#import "../State/ViewLoadInstrumentationState.h"
#import "../System/ViewLoadSwizzlingCallbacks.h"

namespace bugsnag {

class ViewLoadLifecycleHandler {
public:
    virtual void onInstrumentationConfigured(bool isEnabled, BugsnagPerformanceViewControllerInstrumentationCallback callback) noexcept = 0;
    virtual void onLoadView(UIViewController *viewController,
                            ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept = 0;
    virtual void onViewDidLoad(UIViewController *viewController,
                               ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept = 0;
    virtual void onViewWillAppear(UIViewController *viewController,
                                  ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept = 0;
    virtual void onViewDidAppear(UIViewController *viewController,
                                 ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept = 0;
    virtual void onViewWillLayoutSubviews(UIViewController *viewController,
                                          ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept = 0;
    virtual void onViewDidLayoutSubviews(UIViewController *viewController,
                                         ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept = 0;
    virtual void onLoadingIndicatorWasAdded(BugsnagPerformanceLoadingIndicatorView *loadingIndicator) noexcept = 0;
    virtual void onLoadingIndicatorWasRemoved(BugsnagPerformanceLoadingIndicatorView *loadingIndicator) noexcept = 0;
    virtual ~ViewLoadLifecycleHandler() {}
};
}
