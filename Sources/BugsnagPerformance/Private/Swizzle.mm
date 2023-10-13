//
//  Swizzle.mm
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 21.04.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "Swizzle.h"
#import "Utils.h"
#import <objc/runtime.h>

namespace bugsnag {

IMP ObjCSwizzle::setClassMethodImplementation(Class _Nonnull clazz, SEL selector, id _Nonnull implementationBlock) noexcept {
    Method method = class_getClassMethod(clazz, selector);
    if (method) {
        return method_setImplementation(method, imp_implementationWithBlock(implementationBlock));
    } else {
        BSGLogWarning(@"Could not set IMP for selector %s on class %@", sel_getName(selector), clazz);
        return nil;
    }
}

IMP ObjCSwizzle::replaceInstanceMethodOverride(Class cls, SEL selector, id block, const char* objcCallingSignature) noexcept {
    Method method = nil;

    // Not using class_getInstanceMethod because we don't want to modify the
    // superclass's implementation.
    auto methodCount = 0U;
    Method *methods = class_copyMethodList(cls, &methodCount);
    if (methods) {
        for (auto i = 0U; i < methodCount; i++) {
            if (sel_isEqual(method_getName(methods[i]), selector)) {
                method = methods[i];
                break;
            }
        }
        free(methods);
    }

    if (method) {
        // We found a method to replace, so replace it and return the old IMP
        return method_setImplementation(method, imp_implementationWithBlock(block));
    }

    if (objcCallingSignature == nil) {
        // We didn't find an existing method, and we weren't asked to add one either.
        return nil;
    }

    // Try to add a new method to the class.
    IMP newIMP = imp_implementationWithBlock(block);
    if (!class_addMethod(cls, selector, newIMP, objcCallingSignature)) {
        return nil;
    }

    // Find the closest superclass IMP of this method and return it.
    for (cls = [cls superclass]; cls && class_getInstanceMethod(cls, selector); cls = [cls superclass]) {
        method = class_getInstanceMethod(cls, selector);
        if (method) {
            return method_getImplementation(method);
        }
    }

    // We didn't find a superclass IMP of the method, so there's no old IMP to return
    return nil;
}

NSArray<Class> *ObjCSwizzle::getClassesWithSelector(Class cls, SEL selector) noexcept {
    NSMutableArray<Class> *result = [NSMutableArray new];
    for (; class_getInstanceMethod(cls, selector); cls = [cls superclass]) {
        if (!cls) {
            break;
        }
        Class superCls = [cls superclass];
        Method classMethod = class_getInstanceMethod(cls, selector);
        Method superMethod = class_getInstanceMethod(superCls, selector);
        IMP classIMP = classMethod ? method_getImplementation(classMethod) : nil;
        IMP superIMP = superMethod ? method_getImplementation(superMethod) : nil;
        if (classIMP != superIMP) {
            [result addObject:(Class _Nonnull)cls];
        }
    }
    return result;
};


}
