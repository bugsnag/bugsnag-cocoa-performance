//
//  ViewLoadInstrumentation.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 10/10/2022.
//

#import "ViewLoadInstrumentation.h"
#import <BugsnagPerformance/BugsnagPerformanceTrackedViewContainer.h>

#import "../BugsnagPerformanceSpan+Private.h"
#import "../Tracer.h"
#import "../Swizzle.h"
#import "../Utils.h"
#import "../BugsnagSwiftTools.h"
#import "../BugsnagPerformanceCrossTalkAPI.h"

#import <objc/runtime.h>

#if 0
#define Trace NSLog
#else
#define Trace(...)
#endif

using namespace bugsnag;

static constexpr int kAssociatedViewLoadInstrumentationState = 0;
static constexpr int kAssociatedStateView = 0;
static constexpr CGFloat kViewWillAppearPreloadedDelayThreshold = 1.0;

typedef void (^ ViewLoadInstrumentationStateOnDeallocCallback)(ViewLoadInstrumentationState *);

@interface ViewLoadInstrumentationState ()
@property (nonatomic) BOOL loadViewPhaseSpanCreated;
@property (nonatomic) BOOL viewDidLoadPhaseSpanCreated;
@property (nonatomic) BOOL viewWillAppearPhaseSpanCreated;
@property (nonatomic) BOOL viewDidAppearPhaseSpanCreated;
@property (nonatomic) BOOL viewWillLayoutSubviewsPhaseSpanCreated;
@property (nonatomic) BOOL viewDidLayoutSubviewsPhaseSpanCreated;
@property (nonatomic) BOOL viewLoadingPhaseSpanCreated;
@property (nonatomic) BOOL isMarkedAsPreloaded;
@property (nonatomic, nullable, strong) NSDate *viewDidLoadEndTime;
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *overallSpan;
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *viewAppearingSpan;
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *subviewLayoutSpan;
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *loadingPhaseSpan;
@property (nonatomic, nullable) ViewLoadInstrumentationStateOnDeallocCallback onDealloc;
@property (nonatomic, nullable, weak) UIView *view;
@property (nonatomic, nullable) BugsnagPerformanceSpanCondition* loadingPhaseCondition;
@end

@implementation ViewLoadInstrumentationState

- (void)dealloc {
    if (self.onDealloc != nil) {
        self.onDealloc(self);
    }
}

@end

void ViewLoadInstrumentation::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    isEnabled_ = config.enableSwizzling;
    swizzleViewLoadPreMain_ = config.swizzleViewLoadPreMain;
}

void ViewLoadInstrumentation::earlySetup() noexcept {
    if (!isEnabled_) {
        return;
    }
    
    if (swizzleViewLoadPreMain_) {
        for (auto image : imagesToInstrument()) {
            Trace(@"Instrumenting %s", image);
            for (auto cls : viewControllerSubclasses(image)) {
                Trace(@" - %s", class_getName(cls));
                classToIsObserved_[cls] = true;
                instrument(cls);
            }
        }
    } else {
        classToIsObserved_[[UIViewController class]] = true;
        __block auto classToIsObserved = &classToIsObserved_;
        __block bool *isEnabled = &isEnabled_;
        __block auto appPath = NSBundle.mainBundle.bundlePath;
        auto initInstrumentation = ^(id self) {
            auto viewControllerClass = [self class];
            auto viewControllerBundlePath = [NSBundle bundleForClass: viewControllerClass].bundlePath;
            if ([viewControllerBundlePath containsString:appPath]
#if TARGET_OS_SIMULATOR
                // and those loaded from BUILT_PRODUCTS_DIR, because Xcode
                // doesn't embed them when building for the Simulator.
                || [viewControllerBundlePath containsString:@"/DerivedData/"]
#endif
                ) {
                if (*isEnabled && !isClassObserved(viewControllerClass)) {
                    Trace(@"%@   -[%s %s]", self, class_getName(viewControllerClass), sel_getName(selector));
                    instrument(viewControllerClass);
                    (*classToIsObserved)[viewControllerClass] = true;
                }
            }
        };
        SEL selector = @selector(initWithCoder:);
        IMP initWithCoder __block = nullptr;
        initWithCoder = ObjCSwizzle::replaceInstanceMethodOverride([UIViewController class], selector, ^(id self, NSCoder *coder) {
            std::lock_guard<std::recursive_mutex> guard(vcInitMutex_);
            initInstrumentation(self);
            return reinterpret_cast<id (*)(id, SEL, NSCoder *)>(initWithCoder)(self, selector, coder);
        });
        
        selector = @selector(initWithNibName:bundle:);
        IMP initWithNibNameBundle __block = nullptr;
        initWithNibNameBundle = ObjCSwizzle::replaceInstanceMethodOverride([UIViewController class], selector, ^(id self, NSString *name, NSBundle *bundle) {
            std::lock_guard<std::recursive_mutex> guard(vcInitMutex_);
            initInstrumentation(self);
            return reinterpret_cast<id (*)(id, SEL, NSString *, NSBundle *)>(initWithNibNameBundle)(self, selector, name, bundle);
        });
    }
    
    // We need to instrument UIViewController because not all subclasses will
    // override loadView and viewDidAppear:
    instrument([UIViewController class]);
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

    // Also end data loading phase span if it was created
    if (state.viewLoadingPhaseSpanCreated) {
        [state.loadingPhaseSpan end];
    }

    [span end];
}

void
ViewLoadInstrumentation::onLoadView(UIViewController *viewController) noexcept {
    if (!canCreateSpans(viewController)) {
        return;
    }

    auto viewType = BugsnagPerformanceViewTypeUIKit;
    auto name = [BugsnagSwiftTools demangledClassNameFromInstance:viewController];
    SpanOptions options;
    auto span = tracer_->startViewLoadSpan(viewType, name, options);
    [span internalSetMultipleAttributes:spanAttributesProvider_->viewLoadSpanAttributes(name, viewType)];

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

    auto instrumentationState = getInstrumentationState(viewController);
    if (instrumentationState != nil && instrumentationState.overallSpan != nil) {
        instrumentationState.loadingPhaseCondition = [instrumentationState.overallSpan blockWithTimeout:0.1];
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
        [span updateName: [NSString stringWithFormat:@"%@ (pre-loaded)", span.name]];
        [span updateStartTime: viewWillAppearStartTime];
        [span internalSetMultipleAttributes:spanAttributesProvider_->preloadedViewLoadSpanAttributes(className, viewType)];
        instrumentationState.isMarkedAsPreloaded = true;
    }
}

void ViewLoadInstrumentation::updateViewForViewController(UIViewController *viewController, ViewLoadInstrumentationState *instrumentationState) {
    if (viewController == nil || instrumentationState == nil) {
        return;
    }

    UIView *currentView = instrumentationState.view;
    if (currentView != viewController.view) {
        if (currentView != nil) {
            // Remove the old instrumentation state from the view
            objc_setAssociatedObject(currentView, &kAssociatedStateView, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }

        instrumentationState.view = viewController.view;
        objc_setAssociatedObject(viewController.view, &kAssociatedStateView, instrumentationState, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

NSMutableArray<BugsnagPerformanceSpanCondition *> * ViewLoadInstrumentation::startLoadingPhase(UIView *loadingIndicatorView) noexcept {
    NSMutableArray<BugsnagPerformanceSpanCondition *> *newConditions = [NSMutableArray array];
    UIView *superview = loadingIndicatorView.superview;
    while (superview != nil) {
        ViewLoadInstrumentationState *associatedState = objc_getAssociatedObject(superview, &kAssociatedStateView);
        if (associatedState != nil && associatedState.loadingPhaseCondition.isActive) {
            UIViewController *viewController = objc_getAssociatedObject(associatedState, &kAssociatedViewLoadInstrumentationState);

            // Start the phase
            BugsnagPerformanceSpan *span = startViewLoadPhaseSpan(viewController, @"viewDataLoading");
            associatedState.viewLoadingPhaseSpanCreated = YES;
            associatedState.loadingPhaseSpan = span;

            // Block the span
            __strong BugsnagPerformanceSpan *parentSpan = associatedState.overallSpan;
            if (parentSpan != nil) {
                BugsnagPerformanceSpanCondition* condition = [parentSpan blockWithTimeout:0.5];
                [condition upgrade];
                [newConditions addObject:condition];
            }
        }
        superview = superview.superview;
    }

    return newConditions;
}

// Suppress clang-tidy warnings about use of pointer arithmetic and free()
// NOLINTBEGIN(cppcoreguidelines-*)

std::vector<const char *>
ViewLoadInstrumentation::imagesToInstrument() noexcept {
    std::vector<const char *> images;
    auto appPath = NSBundle.mainBundle.bundlePath.UTF8String;
    auto count = 0U;
    auto names = objc_copyImageNames(&count);
    if (names) {
        for (auto i = 0U; i < count; i++) {
            // Instrument all images within the app bundle
            if (strstr(names[i], appPath)
#if TARGET_OS_SIMULATOR
                // and those loaded from BUILT_PRODUCTS_DIR, because Xcode
                // doesn't embed them when building for the Simulator.
                || strstr(names[i], "/DerivedData/")
#endif
                ) {
                images.push_back(names[i]);
            }
        }
        free(names);
    }
    return images;
}

std::vector<Class>
ViewLoadInstrumentation::viewControllerSubclasses(const char *image) noexcept {
    std::vector<Class> classes;
    auto count = 0U;
    auto names = objc_copyClassNamesForImage(image, &count);
    if (names) {
        for (unsigned int i = 0; i < count; i++) {
            auto cls = objc_getClass(names[i]);
            if (cls && isViewControllerSubclass((Class)cls)) {
                classes.push_back(cls);
            }
        }
        free(names);
    }
    return classes;
}

bool
ViewLoadInstrumentation::isViewControllerSubclass(Class cls) noexcept {
    const auto root = [UIViewController class];
    while (cls && cls != root) {
        cls = class_getSuperclass(cls);
    }
    return cls != nil;
}

bool
ViewLoadInstrumentation::canCreateSpans(UIViewController *viewController) noexcept {
    if (!isEnabled_) {
        return false;
    }

    if (!isClassObserved([viewController class])) {
        return false;
    }
    
    // Allow customer code to prevent span creation for this view controller.
    if (callback_ && !callback_(viewController)) {
        return false;
    }
    
    return true;
}

bool
ViewLoadInstrumentation::isClassObserved(Class cls) noexcept {
    auto result = classToIsObserved_.find(cls);
    if (result == classToIsObserved_.end()) {
        return false;
    }
    return (*result).second;
}

BugsnagPerformanceSpan *
ViewLoadInstrumentation::startViewLoadPhaseSpan(UIViewController *viewController, NSString *phase) noexcept {
    if (!canCreateSpans(viewController)) {
        return nullptr;
    }
    auto name = [BugsnagSwiftTools demangledClassNameFromInstance:viewController];
    auto instrumentationState = getInstrumentationState(viewController);
    auto span = tracer_->startViewLoadPhaseSpan(name,
                                                phase,
                                                instrumentationState.overallSpan);
    [span internalSetMultipleAttributes:spanAttributesProvider_->viewLoadPhaseSpanAttributes(name, phase)];

    if (isEarlySpanPhase_) {
        markEarlySpan(span);
    }

    return span;
}

void
ViewLoadInstrumentation::instrumentLoadView(Class cls) noexcept {
    __block SEL selector = @selector(loadView);
    __block bool const * const isEnabled = &isEnabled_;
    __block IMP loadView = ObjCSwizzle::replaceInstanceMethodOverride(cls, selector, ^(id self) {
        if (*isEnabled) {
            // Prevent replacing an existing span for view controllers that override
            // loadView and call through to superclass implementation(s).
            ViewLoadInstrumentationState *instrumentationState = getInstrumentationState(self);
            if (instrumentationState.loadViewPhaseSpanCreated) {
                if (loadView) {
                    reinterpret_cast<void (*)(id, SEL)>(loadView)(self, selector);
                }
                return;
            }
            Trace(@"%@   -[%s %s]", self, class_getName(cls), sel_getName(selector));
            onLoadView(self);
            BugsnagPerformanceSpan *span = startViewLoadPhaseSpan(self, @"loadView");
            if (loadView) {
                reinterpret_cast<void (*)(id, SEL)>(loadView)(self, selector);
            }
            [span end];

            updateViewForViewController(self, instrumentationState);

        } else {
            if (loadView) {
                reinterpret_cast<void (*)(id, SEL)>(loadView)(self, selector);
            }
        }
    });
}

void
ViewLoadInstrumentation::instrumentViewDidLoad(Class cls) noexcept {
    __block SEL selector = @selector(viewDidLoad);
    __block bool const * const isEnabled = &isEnabled_;
    __block IMP viewDidLoad = ObjCSwizzle::replaceInstanceMethodOverride(cls, selector, ^(id self) {
        ViewLoadInstrumentationState *instrumentationState = getInstrumentationState(self);
        if (instrumentationState.overallSpan == nil || !(*isEnabled) || instrumentationState.viewDidLoadPhaseSpanCreated) {
            if (viewDidLoad) {
                reinterpret_cast<void (*)(id, SEL)>(viewDidLoad)(self, selector);
            }
            return;
        }
        
        Trace(@"%@   -[%s %s]", self, class_getName(cls), sel_getName(selector));
        BugsnagPerformanceSpan *span = startViewLoadPhaseSpan(self, @"viewDidLoad");
        instrumentationState.viewDidLoadPhaseSpanCreated = YES;
        if (viewDidLoad) {
            reinterpret_cast<void (*)(id, SEL)>(viewDidLoad)(self, selector);
        }
        [span end];
        instrumentationState.viewDidLoadEndTime = span.endTime;
    });
}

void
ViewLoadInstrumentation::instrumentViewWillAppear(Class cls) noexcept {
    __block SEL selector = @selector(viewWillAppear:);
    __block bool const * const isEnabled = &isEnabled_;
    __block IMP viewWillAppear = ObjCSwizzle::replaceInstanceMethodOverride(cls, selector, ^(id self, BOOL animated) {
        ViewLoadInstrumentationState *instrumentationState = getInstrumentationState(self);
        BugsnagPerformanceSpan *overallSpan = instrumentationState.overallSpan;
        if (overallSpan == nil || !(*isEnabled) || instrumentationState.viewWillAppearPhaseSpanCreated) {
            if (viewWillAppear) {
                reinterpret_cast<void (*)(id, SEL, BOOL)>(viewWillAppear)(self, selector, animated);
            }
            return;
        }
        Trace(@"%@   -[%s %s]", self, class_getName(cls), sel_getName(selector));
        BugsnagPerformanceSpan *span = startViewLoadPhaseSpan(self, @"viewWillAppear");
        instrumentationState.viewWillAppearPhaseSpanCreated = YES;
        if (viewWillAppear) {
            reinterpret_cast<void (*)(id, SEL, BOOL)>(viewWillAppear)(self, selector, animated);
        }
        [span end];
        adjustSpanIfPreloaded(overallSpan, instrumentationState, [span startTime], self);
        BugsnagPerformanceSpan *viewAppearingSpan = startViewLoadPhaseSpan(self, @"View appearing");
        instrumentationState.viewAppearingSpan = viewAppearingSpan;
    });
}

void
ViewLoadInstrumentation::instrumentViewDidAppear(Class cls) noexcept {
    __block SEL selector = @selector(viewDidAppear:);
    __block bool const * const isEnabled = &isEnabled_;
    __block IMP viewDidAppear = ObjCSwizzle::replaceInstanceMethodOverride(cls, selector, ^(id self, BOOL animated) {
        ViewLoadInstrumentationState *instrumentationState = getInstrumentationState(self);
        if (instrumentationState.overallSpan == nil || !(*isEnabled) || instrumentationState.viewDidAppearPhaseSpanCreated) {
            if (viewDidAppear) {
                reinterpret_cast<void (*)(id, SEL, BOOL)>(viewDidAppear)(self, selector, animated);
            }
            return;
        }
        endViewAppearingSpan(instrumentationState, CFAbsoluteTimeGetCurrent());
        BugsnagPerformanceSpan *span = startViewLoadPhaseSpan(self, @"viewDidAppear");
        instrumentationState.viewDidAppearPhaseSpanCreated = YES;
        Trace(@"%@   -[%s %s]", self, class_getName(cls), sel_getName(selector));
        if (viewDidAppear) {
            reinterpret_cast<void (*)(id, SEL, BOOL)>(viewDidAppear)(self, selector, animated);
        }
        [span end];
        onViewDidAppear(self);
    });
}

void
ViewLoadInstrumentation::instrumentViewWillLayoutSubviews(Class cls) noexcept {
    __block SEL selector = @selector(viewWillLayoutSubviews);
    __block bool const * const isEnabled = &isEnabled_;
    __block IMP viewWillLayoutSubviews = ObjCSwizzle::replaceInstanceMethodOverride(cls, selector, ^(id self) {
        ViewLoadInstrumentationState *instrumentationState = getInstrumentationState(self);
        if (instrumentationState.overallSpan == nil || !(*isEnabled) || instrumentationState.viewWillLayoutSubviewsPhaseSpanCreated) {
            if (viewWillLayoutSubviews) {
                reinterpret_cast<void (*)(id, SEL)>(viewWillLayoutSubviews)(self, selector);
            }
            return;
        }
        Trace(@"%@   -[%s %s]", self, class_getName(cls), sel_getName(selector));
        BugsnagPerformanceSpan *span = startViewLoadPhaseSpan(self, @"viewWillLayoutSubviews");
        instrumentationState.viewWillLayoutSubviewsPhaseSpanCreated = YES;
        if (viewWillLayoutSubviews) {
            reinterpret_cast<void (*)(id, SEL)>(viewWillLayoutSubviews)(self, selector);
        }
        [span end];
        BugsnagPerformanceSpan *subviewLayoutSpan = startViewLoadPhaseSpan(self, @"Subview layout");
        instrumentationState.subviewLayoutSpan = subviewLayoutSpan;
    });
}

void
ViewLoadInstrumentation::instrumentViewDidLayoutSubviews(Class cls) noexcept {
    __block SEL selector = @selector(viewDidLayoutSubviews);
    __block bool const * const isEnabled = &isEnabled_;
    __block IMP viewDidLayoutSubviews = ObjCSwizzle::replaceInstanceMethodOverride(cls, selector, ^(id self) {
        ViewLoadInstrumentationState *instrumentationState = getInstrumentationState(self);
        if (instrumentationState.overallSpan == nil || !(*isEnabled) || instrumentationState.viewDidLayoutSubviewsPhaseSpanCreated) {
            if (viewDidLayoutSubviews) {
                reinterpret_cast<void (*)(id, SEL)>(viewDidLayoutSubviews)(self, selector);
            }
            return;
        }
        endSubviewsLayoutSpan(self);
        Trace(@"%@   -[%s %s]", self, class_getName(cls), sel_getName(selector));
        BugsnagPerformanceSpan *span = startViewLoadPhaseSpan(self, @"viewDidLayoutSubviews");
        instrumentationState.viewDidLayoutSubviewsPhaseSpanCreated = YES;
        if (viewDidLayoutSubviews) {
            reinterpret_cast<void (*)(id, SEL)>(viewDidLayoutSubviews)(self, selector);
        }
        [span end];

        auto subviewsDidLayoutAtTime = CFAbsoluteTimeGetCurrent();
        updateViewForViewController(self, instrumentationState);

        void (^endViewAppearingSpanIfNeeded)(ViewLoadInstrumentationState *) = ^void(ViewLoadInstrumentationState *state) {
            auto overallSpan = state.overallSpan;
            if (overallSpan.state == SpanStateOpen) {
                [overallSpan endWithAbsoluteTime:subviewsDidLayoutAtTime];
            }
            endViewAppearingSpan(state, subviewsDidLayoutAtTime);
        };
        
        // If the overall span still hasn't ended when the ViewController is deallocated, use the time from viewDidLayoutSubviews
        instrumentationState.onDealloc = endViewAppearingSpanIfNeeded;
        
        __block __weak UIViewController *weakSelf = self;
        // If the overall span still hasn't ended after 10 seconds, use the time from viewDidLayoutSubviews
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong UIViewController *strongSelf = weakSelf;
            if (strongSelf == nil) {
                return;
            }
            ViewLoadInstrumentationState *state = getInstrumentationState(strongSelf);
            state.onDealloc = nil;
            endViewAppearingSpanIfNeeded(state);
        });
    });
}

void
ViewLoadInstrumentation::instrument(Class cls) noexcept {
    instrumentLoadView(cls);
    instrumentViewDidLoad(cls);
    instrumentViewWillAppear(cls);
    instrumentViewDidAppear(cls);
    instrumentViewWillLayoutSubviews(cls);
    instrumentViewDidLayoutSubviews(cls);
}

// NOLINTEND(cppcoreguidelines-*)
