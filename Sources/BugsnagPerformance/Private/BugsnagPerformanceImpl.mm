//
//  BugsnagPerformanceImpl.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 15.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "BugsnagPerformanceImpl.h"
#import "BSGInternalConfig.h"

using namespace bugsnag;

bool BugsnagPerformanceImpl::start(BugsnagPerformanceConfiguration *configuration, NSError **error) noexcept {
    {
        std::lock_guard<std::mutex> guard(mutex_);
        if (started_) {
            return true;
        }
        started_ = true;
    }

    if (![configuration validate:error]) {
        return false;
    }

    worker_ = [[Worker alloc] initWithInitialTasks:buildInitialTasks()
                                    recurringTasks:buildRecurringTasks()
                                      workInterval:bsgp_performWorkInterval];

    tracer_.start(configuration);
    [worker_ start];

    return true;
}

NSArray<Task> *BugsnagPerformanceImpl::buildInitialTasks() {
    return @[];
}

NSArray<Task> *BugsnagPerformanceImpl::buildRecurringTasks() {
    return @[];
}
