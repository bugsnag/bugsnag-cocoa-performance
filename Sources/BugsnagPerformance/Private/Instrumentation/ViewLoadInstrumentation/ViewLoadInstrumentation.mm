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
static constexpr CGFloat kViewWillAppearPreloadedDelayThreshold = 1.0;

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

    endEarlySpanPhase();
}

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

void ViewLoadInstrumentation::endOverallSpan(UIViewController *viewController) noexcept {
    if (!isEnabled_) {
        return;
    }

    ViewLoadInstrumentationState *state = getInstrumentationState(viewController);
    BugsnagPerformanceSpan *span = state.overallSpan;
    // Prevent calling -[BugsnagPerformanceSpan end] more than once.
    state.overallSpan = nil;
    [[BugsnagPerformanceCrossTalkAPI sharedInstance] willEndViewLoadSpan:span viewController:viewController];

    [span end];
}

void
ViewLoadInstrumentation::onLoadView(UIViewController *viewController) noexcept {
    if (!canCreateSpans(viewController)) {
        return;
    }

    auto span = spanFactory_->startOverallViewLoadSpan(viewController);

    if (isEarlySpanPhase_) {
        markEarlySpan(span);
    }
    auto instrumentationState = [ViewLoadInstrumentationState new];
    instrumentationState.loadViewPhaseSpanCreated = YES;
    instrumentationState.overallSpan = span;

    setInstrumentationState(viewController, instrumentationState);
}

void
ViewLoadInstrumentation::onViewDidAppear(UIViewController *viewController) noexcept {
    if (!isEnabled_) {
        return;
    }
    
    endOverallSpan(viewController);
}

void ViewLoadInstrumentation::endViewAppearingSpan(ViewLoadInstrumentationState *instrumentationState, CFAbsoluteTime atTime) noexcept {
    if (!isEnabled_) {
        return;
    }

    BugsnagPerformanceSpan *span = instrumentationState.viewAppearingSpan;
    [span endWithAbsoluteTime:atTime];

    // Prevent calling -[BugsnagPerformanceSpan end] more than once.
    instrumentationState.viewAppearingSpan = nil;
}

void ViewLoadInstrumentation::endSubviewsLayoutSpan(UIViewController *viewController) noexcept {
    if (!isEnabled_) {
        return;
    }

    auto instrumentationState = getInstrumentationState(viewController);
    BugsnagPerformanceSpan *span = instrumentationState.subviewLayoutSpan;
    [span end];

    // Prevent calling -[BugsnagPerformanceSpan end] more than once.
    instrumentationState.subviewLayoutSpan = nil;
}

void ViewLoadInstrumentation::markEarlySpan(BugsnagPerformanceSpan *span) noexcept {
    std::lock_guard<std::recursive_mutex> guard(earlySpansMutex_);
    [earlySpans_ addObject:span];
}

void ViewLoadInstrumentation::endEarlySpanPhase() noexcept {
    BSGLogDebug(@"ViewLoadInstrumentation::endEarlySpansPhase");
    std::lock_guard<std::recursive_mutex> guard(earlySpansMutex_);
    if (!isEnabled_) {
        for (BugsnagPerformanceSpan *span: earlySpans_) {
            tracer_->cancelQueuedSpan(span);
        }
    }
    earlySpans_ = nil;
    isEarlySpanPhase_ = false;
}

void ViewLoadInstrumentation::adjustSpanIfPreloaded(BugsnagPerformanceSpan *span, ViewLoadInstrumentationState *instrumentationState, NSDate *viewWillAppearStartTime, UIViewController *viewController) noexcept {
    NSDate *viewDidLoadEndTime = instrumentationState.viewDidLoadEndTime;
    if (instrumentationState.isMarkedAsPreloaded || viewDidLoadEndTime == nil) {
        return;
    }
    auto isPreloaded = [viewWillAppearStartTime timeIntervalSinceDate: viewDidLoadEndTime] > kViewWillAppearPreloadedDelayThreshold;
    if (isPreloaded) {
        auto viewType = BugsnagPerformanceViewTypeUIKit;
        auto className = [BugsnagSwiftTools demangledClassNameFromInstance:viewController];
        [span updateName: [NSString stringWithFormat:@"%@ (pre-load)", span.name]];
        [span internalSetMultipleAttributes:spanAttributesProvider_->preloadViewLoadSpanAttributes(className, viewType)];
        instrumentationState.isMarkedAsPreloaded = true;
        [span endWithEndTime:viewDidLoadEndTime];
        
        instrumentationState.overallSpan = spanFactory_->startPreloadedPresentingSpan(viewController);
    }
}

bool
ViewLoadInstrumentation::canCreateSpans(UIViewController *viewController) noexcept {
    if (!isEnabled_) {
        return false;
    }
    
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
        if (*isEnabled) {
            // Prevent replacing an existing span for view controllers that override
            // loadView and call through to superclass implementation(s).
            ViewLoadInstrumentationState *instrumentationState = getInstrumentationState(viewController);
            if (instrumentationState.loadViewPhaseSpanCreated) {
                originalImplementation();
                return;
            }
            Trace(@"%@   -[%s %s]", viewController, class_getName(cls), sel_getName(selector));
            onLoadView(viewController);
            BugsnagPerformanceSpan *span = spanFactory_->startLoadViewSpan(viewController,
                                                                           instrumentationState.overallSpan);
            originalImplementation();
            [span end];
        } else {
            originalImplementation();
        }
    };
    
    swizzlingCallbacks.viewDidLoadCallback = ^(UIViewController *viewController,
                                               ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) {
        ViewLoadInstrumentationState *instrumentationState = getInstrumentationState(viewController);
        if (instrumentationState.overallSpan == nil || !(*isEnabled) || instrumentationState.viewDidLoadPhaseSpanCreated) {
            originalImplementation();
            return;
        }
        
        Trace(@"%@   -[%s %s]", viewController, class_getName(cls), sel_getName(selector));
        BugsnagPerformanceSpan *span = spanFactory_->startViewDidLoadSpan(viewController,
                                                                          instrumentationState.overallSpan);
        instrumentationState.viewDidLoadPhaseSpanCreated = YES;
        originalImplementation();
        [span end];
        instrumentationState.viewDidLoadEndTime = span.endTime;
    };
    
    swizzlingCallbacks.viewWillAppearCallback = ^(UIViewController *viewController,
                                                  ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) {
        ViewLoadInstrumentationState *instrumentationState = getInstrumentationState(viewController);
        BugsnagPerformanceSpan *overallSpan = instrumentationState.overallSpan;
        if (overallSpan == nil || !(*isEnabled) || instrumentationState.viewWillAppearPhaseSpanCreated) {
            originalImplementation();
            return;
        }
        Trace(@"%@   -[%s %s]", viewController, class_getName(cls), sel_getName(selector));
        adjustSpanIfPreloaded(overallSpan, instrumentationState, [NSDate new], viewController);
        BugsnagPerformanceSpan *span = spanFactory_->startViewWillAppearSpan(viewController,
                                                                             instrumentationState.overallSpan);
        instrumentationState.viewWillAppearPhaseSpanCreated = YES;
        originalImplementation();
        [span end];
        BugsnagPerformanceSpan *viewAppearingSpan = spanFactory_->startViewAppearingSpan(viewController,
                                                                                         instrumentationState.overallSpan);
        instrumentationState.viewAppearingSpan = viewAppearingSpan;
    };
    
    swizzlingCallbacks.viewDidAppearCallback = ^(UIViewController *viewController,
                                                 ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) {
        ViewLoadInstrumentationState *instrumentationState = getInstrumentationState(viewController);
        if (instrumentationState.overallSpan == nil || !(*isEnabled) || instrumentationState.viewDidAppearPhaseSpanCreated) {
            originalImplementation();
            return;
        }
        endViewAppearingSpan(instrumentationState, CFAbsoluteTimeGetCurrent());
        BugsnagPerformanceSpan *span = spanFactory_->startViewDidAppearSpan(viewController,
                                                                            instrumentationState.overallSpan);
        instrumentationState.viewDidAppearPhaseSpanCreated = YES;
        Trace(@"%@   -[%s %s]", viewController, class_getName(cls), sel_getName(selector));
        originalImplementation();
        [span end];
        onViewDidAppear(viewController);
    };
    
    swizzlingCallbacks.viewWillLayoutSubviewsCallback = ^(UIViewController *viewController,
                                                          ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) {
        ViewLoadInstrumentationState *instrumentationState = getInstrumentationState(viewController);
        if (instrumentationState.overallSpan == nil || !(*isEnabled) || instrumentationState.viewWillLayoutSubviewsPhaseSpanCreated) {
            originalImplementation();
            return;
        }
        Trace(@"%@   -[%s %s]", viewController, class_getName(cls), sel_getName(selector));
        BugsnagPerformanceSpan *span = spanFactory_->startViewWillLayoutSubviewsSpan(viewController,
                                                                                     instrumentationState.overallSpan);
        instrumentationState.viewWillLayoutSubviewsPhaseSpanCreated = YES;
        originalImplementation();
        [span end];
        BugsnagPerformanceSpan *subviewLayoutSpan = spanFactory_->startSubviewsLayoutSpan(viewController,
                                                                                          instrumentationState.overallSpan);
        instrumentationState.subviewLayoutSpan = subviewLayoutSpan;
    };
    
    swizzlingCallbacks.viewDidLayoutSubviewsCallback = ^(UIViewController *viewController,
                                                         ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) {
        ViewLoadInstrumentationState *instrumentationState = getInstrumentationState(viewController);
        if (instrumentationState.overallSpan == nil || !(*isEnabled) || instrumentationState.viewDidLayoutSubviewsPhaseSpanCreated) {
            originalImplementation();
            return;
        }
        endSubviewsLayoutSpan(viewController);
        Trace(@"%@   -[%s %s]", viewController, class_getName(cls), sel_getName(selector));
        BugsnagPerformanceSpan *span = spanFactory_->startViewDidLayoutSubviewsSpan(viewController,
                                                                                    instrumentationState.overallSpan);
        instrumentationState.viewDidLayoutSubviewsPhaseSpanCreated = YES;
        originalImplementation();
        [span end];
        auto subviewsDidLayoutAtTime = CFAbsoluteTimeGetCurrent();
        
        void (^endViewAppearingSpanIfNeeded)(ViewLoadInstrumentationState *) = ^void(ViewLoadInstrumentationState *state) {
            auto overallSpan = state.overallSpan;
            if (overallSpan.state == SpanStateOpen) {
                [overallSpan endWithAbsoluteTime:subviewsDidLayoutAtTime];
            }
            endViewAppearingSpan(state, subviewsDidLayoutAtTime);
        };
        
        // If the overall span still hasn't ended when the ViewController is deallocated, use the time from viewDidLayoutSubviews
        instrumentationState.onDealloc = endViewAppearingSpanIfNeeded;
        
        __block __weak UIViewController *weakViewController = viewController;
        // If the overall span still hasn't ended after 10 seconds, use the time from viewDidLayoutSubviews
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong UIViewController *strongViewController = weakViewController;
            if (strongViewController == nil) {
                return;
            }
            ViewLoadInstrumentationState *state = getInstrumentationState(strongViewController);
            state.onDealloc = nil;
            endViewAppearingSpanIfNeeded(state);
        });
    };
    
    return swizzlingCallbacks;
}

// NOLINTEND(cppcoreguidelines-*)
