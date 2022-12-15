//
//  BugsnagPerformanceImpl.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 15.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "BugsnagPerformanceImpl.h"

using namespace bugsnag;

bool BugsnagPerformanceImpl::start(BugsnagPerformanceConfiguration *configuration, NSError **error) noexcept {
    if (![configuration validate:error]) {
        return false;
    }
    tracer.start(configuration);
    return true;
}
