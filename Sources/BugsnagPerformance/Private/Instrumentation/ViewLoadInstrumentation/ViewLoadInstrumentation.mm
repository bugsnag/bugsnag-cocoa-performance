//
//  ViewLoadInstrumentation.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 10/10/2022.
//

#import "ViewLoadInstrumentation.h"
#import <BugsnagPerformance/BugsnagPerformanceTrackedViewContainer.h>

#import "../../BugsnagPerformanceSpan+Private.h"
#import "../../Tracer.h"
#import "../../Swizzle.h"
#import "../../Utils.h"
#import "../../BugsnagSwiftTools.h"
#import "../../BugsnagPerformanceCrossTalkAPI.h"

#if 0
#define Trace NSLog
#else
#define Trace(...)
#endif

using namespace bugsnag;

#pragma mark Phased startup

void ViewLoadInstrumentation::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    isEnabled_ = config.enableSwizzling;
    swizzleViewLoadPreMain_ = config.swizzleViewLoadPreMain;
}

void ViewLoadInstrumentation::earlySetup() noexcept {
    if (!isEnabled_) {
        return;
    }
    auto swizzlingCallbacks = createViewLoadSwizzlingCallbacks();
    
    if (swizzleViewLoadPreMain_) {
        for (auto image : systemUtils_->imagesToInstrument()) {
            Trace(@"Instrumenting %s", image);
            for (auto cls : systemUtils_->viewControllerSubclasses(image)) {
                Trace(@" - %s", class_getName(cls));
                swizzlingHandler_->instrument(cls, swizzlingCallbacks);
            }
        }
    } else {
        swizzlingHandler_->instrumentInit([UIViewController class],
                                          swizzlingCallbacks,
                                          &isEnabled_);
    }
    
    // We need to instrument UIViewController because not all subclasses will
    // override loadView and viewDidAppear:
    swizzlingHandler_->instrument([UIViewController class], swizzlingCallbacks);
}

void
ViewLoadInstrumentation::configure(BugsnagPerformanceConfiguration *config) noexcept {
    if (!isEnabled_ && config.autoInstrumentViewControllers) {
        BSGLogInfo(@"Automatic view load instrumentation has been disabled because "
                   "bugsnag/performance/disableSwizzling in Info.plist is set to YES");
    }

    isEnabled_ &= config.autoInstrumentViewControllers;
    auto callback = config.viewControllerInstrumentationCallback;
    if (callback != nullptr) {
        callback_ = callback;
    }

    lifecycleHandler_->onInstrumentationConfigured(isEnabled_, callback);
}

#pragma mark Loading indicator

void
ViewLoadInstrumentation::loadingIndicatorWasAdded(BugsnagPerformanceLoadingIndicatorView *loadingIndicatorView) noexcept {
    lifecycleHandler_->onLoadingIndicatorWasAdded(loadingIndicatorView);
}


#pragma mark Helpers

bool
ViewLoadInstrumentation::canCreateSpans(UIViewController *viewController) noexcept {
    // Allow customer code to prevent span creation for this view controller.
    if (callback_ && !callback_(viewController)) {
        return false;
    }
    
    return true;
}

ViewLoadSwizzlingCallbacks *
ViewLoadInstrumentation::createViewLoadSwizzlingCallbacks() noexcept {
    auto swizzlingCallbacks = [ViewLoadSwizzlingCallbacks new];
    
    __block bool const * const isEnabled = &isEnabled_;
    
    swizzlingCallbacks.loadViewCallback = ^(UIViewController *viewController,
                                            ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) {
        if (!(*isEnabled) || !canCreateSpans(viewController)) {
            originalImplementation();
            return;
        }
        lifecycleHandler_->onLoadView(viewController,
                                      originalImplementation);
    };
    
    swizzlingCallbacks.viewDidLoadCallback = ^(UIViewController *viewController,
                                               ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) {
        if (!(*isEnabled)) {
            originalImplementation();
            return;
        }
        lifecycleHandler_->onViewDidLoad(viewController,
                                         originalImplementation);
    };
    
    swizzlingCallbacks.viewWillAppearCallback = ^(UIViewController *viewController,
                                                  ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) {
        if (!(*isEnabled)) {
            originalImplementation();
            return;
        }
        lifecycleHandler_->onViewWillAppear(viewController,
                                            originalImplementation);
    };
    
    swizzlingCallbacks.viewDidAppearCallback = ^(UIViewController *viewController,
                                                 ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) {
        if (!(*isEnabled)) {
            originalImplementation();
            return;
        }
        lifecycleHandler_->onViewDidAppear(viewController,
                                           originalImplementation);
    };
    
    swizzlingCallbacks.viewWillLayoutSubviewsCallback = ^(UIViewController *viewController,
                                                          ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) {
        if (!(*isEnabled)) {
            originalImplementation();
            return;
        }
        lifecycleHandler_->onViewWillLayoutSubviews(viewController,
                                                    originalImplementation);
    };
    
    swizzlingCallbacks.viewDidLayoutSubviewsCallback = ^(UIViewController *viewController,
                                                         ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) {
        if (!(*isEnabled)) {
            originalImplementation();
            return;
        }
        lifecycleHandler_->onViewDidLayoutSubviews(viewController,
                                                   originalImplementation);
    };
    
    return swizzlingCallbacks;
}

// NOLINTEND(cppcoreguidelines-*)
