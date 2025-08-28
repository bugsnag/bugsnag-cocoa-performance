//
//  ViewLoadInstrumentationStateRepositoryImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 28/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadInstrumentationStateRepositoryImpl.h"

#import <objc/runtime.h>

static constexpr int kAssociatedViewLoadInstrumentationState = 0;

using namespace bugsnag;

void
ViewLoadInstrumentationStateRepositoryImpl::setInstrumentationState(UIViewController *viewController, ViewLoadInstrumentationState * _Nullable state) noexcept {
    if (viewController == nil) {
        return;
    }
    objc_setAssociatedObject(viewController, &kAssociatedViewLoadInstrumentationState, state,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

ViewLoadInstrumentationState *
ViewLoadInstrumentationStateRepositoryImpl::getInstrumentationState(UIViewController *viewController) noexcept {
    if (viewController == nil) {
        return nil;
    }
    return objc_getAssociatedObject(viewController, &kAssociatedViewLoadInstrumentationState);
}
