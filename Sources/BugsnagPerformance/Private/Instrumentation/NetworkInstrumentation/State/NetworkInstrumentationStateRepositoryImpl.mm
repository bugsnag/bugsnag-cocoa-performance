//
//  NetworkInstrumentationStateRepositoryImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 01/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NetworkInstrumentationStateRepositoryImpl.h"

#import <objc/runtime.h>

static constexpr int kAssociatedNetworkInstrumentationState = 0;

using namespace bugsnag;

void
NetworkInstrumentationStateRepositoryImpl::setInstrumentationState(NSURLSessionTask *task, NetworkInstrumentationState * _Nullable state) noexcept {
    if (task == nil) {
        return;
    }
    objc_setAssociatedObject(task, &kAssociatedNetworkInstrumentationState, state,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

NetworkInstrumentationState *
NetworkInstrumentationStateRepositoryImpl::getInstrumentationState(NSURLSessionTask *task) noexcept {
    if (task == nil) {
        return nil;
    }
    return objc_getAssociatedObject(task, &kAssociatedNetworkInstrumentationState);
}
