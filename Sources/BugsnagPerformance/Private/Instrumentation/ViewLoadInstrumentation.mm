//
//  ViewLoadInstrumentation.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 10/10/2022.
//

#import "ViewLoadInstrumentation.h"

#import "../BugsnagPerformanceSpan+Private.h"
#import "../Span.h"
#import "../Tracer.h"

#import <objc/runtime.h>

#if 0
#define Trace NSLog
#else
#define Trace(...)
#endif

using namespace bugsnag;

static constexpr int kAssociatedSpan = 0;

void
ViewLoadInstrumentation::start() noexcept {
    auto observedClasses = [NSMutableSet<Class> set];
    
    for (auto image : imagesToInstrument()) {
        Trace(@"Instrumenting %s", image);
        for (auto cls : viewControllerSubclasses(image)) {
            Trace(@" - %s", class_getName(cls));
            [observedClasses addObject:cls];
            instrument(cls);
        }
    }
    
    observedClasses_ = observedClasses;
    
    // We need to instrument UIViewController because not all subclasses will
    // override loadView and viewDidAppear:
    instrument([UIViewController class]);
}

void
ViewLoadInstrumentation::onLoadView(UIViewController *viewController) noexcept {
    if (![observedClasses_ containsObject:[viewController class]]) {
        return;
    }
    
    // Allow customer code to prevent span creation for this view controller.
    if (callback_ && !callback_(viewController)) {
        return;
    }
    
    // Prevent replacing an existing span for view controllers that override
    // loadView and call through to superclass implementation(s).
    if (objc_getAssociatedObject(viewController, &kAssociatedSpan)) {
        return;
    }
    
    auto span = [[BugsnagPerformanceSpan alloc] initWithSpan:
                 tracer_.startViewLoadSpan(BugsnagPerformanceViewTypeUIKit,
                                           NSStringFromClass([viewController class]),
                                           defaultSpanOptionsForViewLoad())];
    
    objc_setAssociatedObject(viewController, &kAssociatedSpan, span,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

void
ViewLoadInstrumentation::onViewDidAppear(UIViewController *viewController) noexcept {
    BugsnagPerformanceSpan *span = objc_getAssociatedObject(viewController, &kAssociatedSpan);
    [span end];
    
    // Prevent calling -[BugsnagPerformanceSpan end] more than once.
    objc_setAssociatedObject(viewController, &kAssociatedSpan, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
            if (isViewControllerSubclass(cls)) {
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

void
ViewLoadInstrumentation::instrument(Class cls) noexcept {
    SEL selector = @selector(loadView);
    IMP loadView __block = nullptr;
    loadView = overrideImplementation(cls, selector, ^(id self){
        Trace(@"%@   -[%s %s]", self, class_getName(cls), sel_getName(selector));
        onLoadView(self);
        reinterpret_cast<void (*)(id, SEL)>(loadView)(self, selector);
    });
    
    selector = @selector(viewDidAppear:);
    IMP viewDidAppear __block = nullptr;
    viewDidAppear = overrideImplementation(cls, selector, ^(id self, BOOL animated){
        Trace(@"%@   -[%s %s]", self, class_getName(cls), sel_getName(selector));
        reinterpret_cast<void (*)(id, SEL, BOOL)>(viewDidAppear)(self, selector, animated);
        onViewDidAppear(self);
    });
}

IMP
ViewLoadInstrumentation::overrideImplementation(Class cls, SEL name, id block) noexcept {
    Method method = nullptr;
    
    // Not using class_getInstanceMethod because we don't want to modify the
    // superclass's implementation.
    auto methodCount = 0U;
    Method *methods = class_copyMethodList(cls, &methodCount);
    if (methods) {
        for (auto i = 0U; i < methodCount; i++) {
            if (sel_isEqual(method_getName(methods[i]), name)) {
                method = methods[i];
                break;
            }
        }
        free(methods);
    }
    
    if (!method) {
        return nullptr;
    }
    
    return method_setImplementation(method, imp_implementationWithBlock(block));
}

// NOLINTEND(cppcoreguidelines-*)
