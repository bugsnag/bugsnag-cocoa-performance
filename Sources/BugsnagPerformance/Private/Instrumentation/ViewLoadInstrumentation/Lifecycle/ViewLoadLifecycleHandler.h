//
//  ViewLoadLifecycleHandler.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 21/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import "../State/ViewLoadInstrumentationState.h"
#import "../System/ViewLoadSwizzlingCallbacks.h"

namespace bugsnag {

class ViewLoadLifecycleHandler {
public:
    virtual void onInstrumentationConfigured(bool isEnabled, BugsnagPerformanceViewControllerInstrumentationCallback callback) noexcept = 0;
    virtual void onLoadView(ViewLoadInstrumentationState *state,
                            UIViewController *viewController,
                            ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept = 0;
    virtual void onViewDidLoad(ViewLoadInstrumentationState *state,
                               UIViewController *viewController,
                               ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept = 0;
    virtual void onViewWillAppear(ViewLoadInstrumentationState *state,
                                  UIViewController *viewController,
                                  ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept = 0;
    virtual void onViewDidAppear(ViewLoadInstrumentationState *state,
                                 UIViewController *viewController,
                                 ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept = 0;
    virtual void onViewWillLayoutSubviews(ViewLoadInstrumentationState *state,
                                          UIViewController *viewController,
                                          ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept = 0;
    virtual void onViewDidLayoutSubviews(ViewLoadInstrumentationState *state,
                                         UIViewController *viewController,
                                         ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept = 0;
    virtual ~ViewLoadLifecycleHandler() {}
};
}
