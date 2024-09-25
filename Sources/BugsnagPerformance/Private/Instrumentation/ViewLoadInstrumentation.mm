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

#import <objc/runtime.h>

#if 0
#define Trace NSLog
#else
#define Trace(...)
#endif

using namespace bugsnag;

static constexpr int kAssociatedViewLoadSpan = 0;
static constexpr int kAssociatedViewAppearingSpan = 0;
static constexpr int kAssociatedSubviewLayoutSpan = 0;
static constexpr int kAssociatedViewLoadInstrumentationState = 0;
static constexpr CGFloat kViewWillAppearPreloadedDelayThreshold = 1.0;

@implementation ViewLoadInstrumentationState
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

BugsnagPerformanceSpan *ViewLoadInstrumentation::getOverallSpan(UIViewController *viewController) noexcept {
    if (viewController != nil) {
        return objc_getAssociatedObject(viewController, &kAssociatedViewLoadSpan);
    }
    return nil;
}

void ViewLoadInstrumentation::setOverallSpan(UIViewController *viewController, BugsnagPerformanceSpan *span) noexcept {
    objc_setAssociatedObject(viewController, &kAssociatedViewLoadSpan, span,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

void ViewLoadInstrumentation::endOverallSpan(UIViewController *viewController) noexcept {
    if (!isEnabled_) {
        return;
    }

    BugsnagPerformanceSpan *span = getOverallSpan(viewController);
    // Prevent calling -[BugsnagPerformanceSpan end] more than once.
    setOverallSpan(viewController, nil);

    [span end];
}

void
ViewLoadInstrumentation::onLoadView(UIViewController *viewController) noexcept {
    if (!canCreateSpans(viewController)) {
        return;
    }

    auto viewType = BugsnagPerformanceViewTypeUIKit;
    auto name = nameForViewController(viewController);
    SpanOptions options;
    auto span = tracer_->startViewLoadSpan(viewType, name, options);
    [span internalSetMultipleAttributes:spanAttributesProvider_->viewLoadSpanAttributes(name, viewType)];

    if (isEarlySpanPhase_) {
        markEarlySpan(span);
    }
    auto instrumentationState = [ViewLoadInstrumentationState new];
    instrumentationState.loadViewPhaseSpanCreated = YES;

    setOverallSpan(viewController, span);
    objc_setAssociatedObject(viewController, &kAssociatedViewLoadInstrumentationState, instrumentationState,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

void
ViewLoadInstrumentation::onViewDidAppear(UIViewController *viewController) noexcept {
    if (!isEnabled_) {
        return;
    }

    endOverallSpan(viewController);
}

void ViewLoadInstrumentation::endViewAppearingSpan(UIViewController *viewController, CFAbsoluteTime atTime) noexcept {
    if (!isEnabled_) {
        return;
    }

    BugsnagPerformanceSpan *span = objc_getAssociatedObject(viewController, &kAssociatedViewAppearingSpan);
    [span endWithAbsoluteTime:atTime];

    // Prevent calling -[BugsnagPerformanceSpan end] more than once.
    objc_setAssociatedObject(viewController, &kAssociatedViewAppearingSpan, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

void ViewLoadInstrumentation::endSubviewsLayoutSpan(UIViewController *viewController) noexcept {
    if (!isEnabled_) {
        return;
    }

    BugsnagPerformanceSpan *span = objc_getAssociatedObject(viewController, &kAssociatedSubviewLayoutSpan);
    [span end];

    // Prevent calling -[BugsnagPerformanceSpan end] more than once.
    objc_setAssociatedObject(viewController, &kAssociatedSubviewLayoutSpan, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
        auto className = NSStringFromClass([viewController class]);
        [span updateName: [NSString stringWithFormat:@"%@ (pre-loaded)", span.name]];
        [span updateStartTime: viewWillAppearStartTime];
        [span internalSetMultipleAttributes:spanAttributesProvider_->preloadedViewLoadSpanAttributes(className, viewType)];
        instrumentationState.isMarkedAsPreloaded = true;
    }
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

NSString *
ViewLoadInstrumentation::nameForViewController(UIViewController *viewController) noexcept {
    if ([viewController respondsToSelector:@selector(bugsnagPerformanceTrackedViewName)]) {
        return [(id)viewController bugsnagPerformanceTrackedViewName];
    }
    return NSStringFromClass([viewController class]);
}

BugsnagPerformanceSpan *
ViewLoadInstrumentation::startViewLoadPhaseSpan(UIViewController *viewController, NSString *phase) noexcept {
    if (!canCreateSpans(viewController)) {
        return nullptr;
    }
    auto name = nameForViewController(viewController);
    auto span = tracer_->startViewLoadPhaseSpan(name, phase, getOverallSpan(viewController));
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
            ViewLoadInstrumentationState *instrumentationState = objc_getAssociatedObject(self, &kAssociatedViewLoadInstrumentationState);
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
        ViewLoadInstrumentationState *instrumentationState = objc_getAssociatedObject(self, &kAssociatedViewLoadInstrumentationState);
        if (getOverallSpan(self) == nil || !(*isEnabled) || instrumentationState.viewDidLoadPhaseSpanCreated) {
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
        ViewLoadInstrumentationState *instrumentationState = objc_getAssociatedObject(self, &kAssociatedViewLoadInstrumentationState);
        BugsnagPerformanceSpan *overallSpan = getOverallSpan(self);
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
        objc_setAssociatedObject(self, &kAssociatedViewAppearingSpan, viewAppearingSpan,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
}

void
ViewLoadInstrumentation::instrumentViewDidAppear(Class cls) noexcept {
    __block SEL selector = @selector(viewDidAppear:);
    __block bool const * const isEnabled = &isEnabled_;
    __block IMP viewDidAppear = ObjCSwizzle::replaceInstanceMethodOverride(cls, selector, ^(id self, BOOL animated) {
        ViewLoadInstrumentationState *instrumentationState = objc_getAssociatedObject(self, &kAssociatedViewLoadInstrumentationState);
        if (getOverallSpan(self) == nil || !(*isEnabled) || instrumentationState.viewDidAppearPhaseSpanCreated) {
            if (viewDidAppear) {
                reinterpret_cast<void (*)(id, SEL, BOOL)>(viewDidAppear)(self, selector, animated);
            }
            return;
        }
        endViewAppearingSpan(self, CFAbsoluteTimeGetCurrent());
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
        ViewLoadInstrumentationState *instrumentationState = objc_getAssociatedObject(self, &kAssociatedViewLoadInstrumentationState);
        if (getOverallSpan(self) == nil || !(*isEnabled) || instrumentationState.viewWillLayoutSubviewsPhaseSpanCreated) {
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
        objc_setAssociatedObject(self, &kAssociatedSubviewLayoutSpan, subviewLayoutSpan,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
}

void
ViewLoadInstrumentation::instrumentViewDidLayoutSubviews(Class cls) noexcept {
    __block SEL selector = @selector(viewDidLayoutSubviews);
    __block bool const * const isEnabled = &isEnabled_;
    __block IMP viewDidLayoutSubviews = ObjCSwizzle::replaceInstanceMethodOverride(cls, selector, ^(id self) {
        ViewLoadInstrumentationState *instrumentationState = objc_getAssociatedObject(self, &kAssociatedViewLoadInstrumentationState);
        if (getOverallSpan(self) == nil || !(*isEnabled) || instrumentationState.viewDidLayoutSubviewsPhaseSpanCreated) {
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
        __block UIViewController *blockSelf = self;
        // If the overall span still hasn't ended after 10 seconds, use the time from viewDidLayoutSubviews
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            auto overallSpan = getOverallSpan(blockSelf);
            if (overallSpan.state == SpanStateOpen) {
                [overallSpan endWithAbsoluteTime:subviewsDidLayoutAtTime];
            }
            endViewAppearingSpan(self, subviewsDidLayoutAtTime);
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
