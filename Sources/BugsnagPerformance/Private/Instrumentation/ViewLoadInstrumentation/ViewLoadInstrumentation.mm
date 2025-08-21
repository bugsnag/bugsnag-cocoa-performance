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

#import <objc/runtime.h>

#if 0
#define Trace NSLog
#else
#define Trace(...)
#endif

using namespace bugsnag;

static constexpr int kAssociatedViewLoadInstrumentationState = 0;

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

#pragma mark State

ViewLoadInstrumentationState *ViewLoadInstrumentation::getInstrumentationState(UIViewController *viewController) noexcept {
    if (viewController != nil) {
        return objc_getAssociatedObject(viewController, &kAssociatedViewLoadInstrumentationState);
    }
    return nil;
}

void ViewLoadInstrumentation::setInstrumentationState(UIViewController *viewController, ViewLoadInstrumentationState *state) noexcept {
    objc_setAssociatedObject(viewController, &kAssociatedViewLoadInstrumentationState, state,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
        auto state = [ViewLoadInstrumentationState new];
        state.viewController = viewController;
        setInstrumentationState(viewController, state);
        lifecycleHandler_->onLoadView(state,
                                      viewController,
                                      originalImplementation);
    };
    
    swizzlingCallbacks.viewDidLoadCallback = ^(UIViewController *viewController,
                                               ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) {
        if (!(*isEnabled)) {
            originalImplementation();
            return;
        }
        ViewLoadInstrumentationState *state = getInstrumentationState(viewController);
        lifecycleHandler_->onViewDidLoad(state,
                                         viewController,
                                         originalImplementation);
    };
    
    swizzlingCallbacks.viewWillAppearCallback = ^(UIViewController *viewController,
                                                  ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) {
        if (!(*isEnabled)) {
            originalImplementation();
            return;
        }
        ViewLoadInstrumentationState *state = getInstrumentationState(viewController);
        lifecycleHandler_->onViewWillAppear(state,
                                            viewController,
                                            originalImplementation);
    };
    
    swizzlingCallbacks.viewDidAppearCallback = ^(UIViewController *viewController,
                                                 ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) {
        if (!(*isEnabled)) {
            originalImplementation();
            return;
        }
        ViewLoadInstrumentationState *state = getInstrumentationState(viewController);
        lifecycleHandler_->onViewDidAppear(state,
                                           viewController,
                                           originalImplementation);
    };
    
    swizzlingCallbacks.viewWillLayoutSubviewsCallback = ^(UIViewController *viewController,
                                                          ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) {
        if (!(*isEnabled)) {
            originalImplementation();
            return;
        }
        ViewLoadInstrumentationState *state = getInstrumentationState(viewController);
        lifecycleHandler_->onViewWillLayoutSubviews(state,
                                                    viewController,
                                                    originalImplementation);
    };
    
    swizzlingCallbacks.viewDidLayoutSubviewsCallback = ^(UIViewController *viewController,
                                                         ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) {
        if (!(*isEnabled)) {
            originalImplementation();
            return;
        }
        ViewLoadInstrumentationState *state = getInstrumentationState(viewController);
        lifecycleHandler_->onViewDidLayoutSubviews(state,
                                                   viewController,
                                                   originalImplementation);
    };
    
    return swizzlingCallbacks;
}

// NOLINTEND(cppcoreguidelines-*)
