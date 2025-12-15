//
//  ViewLoadSwizzlingHandlerImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ViewLoadSwizzlingHandlerImpl.h"
#import "../../../Swizzle.h"

#import <objc/runtime.h>

using namespace bugsnag;

#pragma mark Swizzling helpers

void instrumentLoadView(Class cls, ViewLoadSwizzlingCallbacks *callbacks) noexcept {
    __block SEL selector = @selector(loadView);
    __block IMP loadView = ObjCSwizzle::replaceInstanceMethodOverride(cls, selector, ^(id self) {
        callbacks.loadViewCallback(self, ^{
            if (loadView) {
                reinterpret_cast<void (*)(id, SEL)>(loadView)(self, selector);
            }
        });
    });
}

void instrumentViewDidLoad(Class cls, ViewLoadSwizzlingCallbacks *callbacks) noexcept {
    __block SEL selector = @selector(viewDidLoad);
    __block IMP viewDidLoad = ObjCSwizzle::replaceInstanceMethodOverride(cls, selector, ^(id self) {
        callbacks.viewDidLoadCallback(self, ^{
            if (viewDidLoad) {
                reinterpret_cast<void (*)(id, SEL)>(viewDidLoad)(self, selector);
            }
        });
    });
}

void instrumentViewWillAppear(Class cls, ViewLoadSwizzlingCallbacks *callbacks) noexcept {
    __block SEL selector = @selector(viewWillAppear:);
    __block IMP viewWillAppear = ObjCSwizzle::replaceInstanceMethodOverride(cls, selector, ^(id self, BOOL animated) {
        callbacks.viewWillAppearCallback(self, ^{
            if (viewWillAppear) {
                reinterpret_cast<void (*)(id, SEL, BOOL)>(viewWillAppear)(self, selector, animated);
            }
        });
    });
}

void instrumentViewDidAppear(Class cls, ViewLoadSwizzlingCallbacks *callbacks) noexcept {
    __block SEL selector = @selector(viewDidAppear:);
    __block IMP viewDidAppear = ObjCSwizzle::replaceInstanceMethodOverride(cls, selector, ^(id self, BOOL animated) {
        callbacks.viewDidAppearCallback(self, ^{
            if (viewDidAppear) {
                reinterpret_cast<void (*)(id, SEL, BOOL)>(viewDidAppear)(self, selector, animated);
            }
        });
    });
}

void instrumentViewWillLayoutSubviews(Class cls, ViewLoadSwizzlingCallbacks *callbacks) noexcept {
    __block SEL selector = @selector(viewWillLayoutSubviews);
    __block IMP viewWillLayoutSubviews = ObjCSwizzle::replaceInstanceMethodOverride(cls, selector, ^(id self) {
        callbacks.viewWillLayoutSubviewsCallback(self, ^{
            if (viewWillLayoutSubviews) {
                reinterpret_cast<void (*)(id, SEL)>(viewWillLayoutSubviews)(self, selector);
            }
        });
    });
}

void instrumentViewDidLayoutSubviews(Class cls, ViewLoadSwizzlingCallbacks *callbacks) noexcept {
    __block SEL selector = @selector(viewDidLayoutSubviews);
    __block IMP viewDidLayoutSubviews = ObjCSwizzle::replaceInstanceMethodOverride(cls, selector, ^(id self) {
        callbacks.viewDidLayoutSubviewsCallback(self, ^{
            if (viewDidLayoutSubviews) {
                reinterpret_cast<void (*)(id, SEL)>(viewDidLayoutSubviews)(self, selector);
            }
        });
    });
}

void instrumentViewWillDisappear(Class cls, ViewLoadSwizzlingCallbacks *callbacks) noexcept {
    __block SEL selector = @selector(viewWillDisappear:);
    __block IMP viewWillDisappear = ObjCSwizzle::replaceInstanceMethodOverride(cls, selector, ^(id self, BOOL animated) {
        callbacks.viewWillDisappearCallback(self, ^{
            if (viewWillDisappear) {
                reinterpret_cast<void (*)(id, SEL, BOOL)>(viewWillDisappear)(self, selector, animated);
            }
        });
    });
}

#pragma mark Instrumentation

void
ViewLoadSwizzlingHandlerImpl::instrument(Class cls, ViewLoadSwizzlingCallbacks *callbacks) noexcept {
    classToIsObserved_[cls] = true;
    instrumentLoadView(cls, callbacks);
    instrumentViewDidLoad(cls, callbacks);
    instrumentViewWillAppear(cls, callbacks);
    instrumentViewDidAppear(cls, callbacks);
    instrumentViewWillLayoutSubviews(cls, callbacks);
    instrumentViewDidLayoutSubviews(cls, callbacks);
    instrumentViewWillDisappear(cls, callbacks);
}

void
ViewLoadSwizzlingHandlerImpl::instrumentInit(Class cls, ViewLoadSwizzlingCallbacks *callbacks, bool *isEnabled) noexcept {
    classToIsObserved_[cls] = true;
    __block auto classToIsObserved = &classToIsObserved_;
    __block auto appPath = NSBundle.mainBundle.bundlePath;
    __block bool *blockIsEnabled = isEnabled;
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
            if (*blockIsEnabled && !isClassObserved(viewControllerClass)) {
                this->instrument(viewControllerClass, callbacks);
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

#pragma mark Helpers

bool
ViewLoadSwizzlingHandlerImpl::isClassObserved(Class cls) noexcept {
    auto result = classToIsObserved_.find(cls);
    if (result == classToIsObserved_.end()) {
        return false;
    }
    return (*result).second;
}
