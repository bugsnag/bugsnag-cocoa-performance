//
//  BugsnagPerformanceImpl.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 15.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import <BugsnagPerformance/BugsnagPerformanceViewType.h>
#import "Tracer.h"
#import "BugsnagPerformanceSpan+Private.h"
#import "Worker.h"

#import <mutex>

namespace bugsnag {
class BugsnagPerformanceImpl {
public:
    BugsnagPerformanceImpl() noexcept
    : batch_(std::make_shared<Batch>())
    , tracer_(batch_)
    {};
    
    bool start(BugsnagPerformanceConfiguration *configuration, NSError **error) noexcept;
    
    void reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept {
        tracer_.reportNetworkSpan(task, metrics);
    }

    BugsnagPerformanceSpan *startSpan(NSString *name) {
        return [[BugsnagPerformanceSpan alloc] initWithSpan:
                tracer_.startSpan(name, CFAbsoluteTimeGetCurrent())];
    }

    BugsnagPerformanceSpan *startSpan(NSString *name, NSDate *startTime) {
        return [[BugsnagPerformanceSpan alloc] initWithSpan:
                tracer_.startSpan(name, startTime.timeIntervalSinceReferenceDate)];
    }

    BugsnagPerformanceSpan *startViewLoadSpan(NSString *name, BugsnagPerformanceViewType viewType) {
        return [[BugsnagPerformanceSpan alloc] initWithSpan:
                tracer_.startViewLoadedSpan(viewType, name, CFAbsoluteTimeGetCurrent())];
    }

    BugsnagPerformanceSpan *startViewLoadSpan(NSString *name, BugsnagPerformanceViewType viewType, NSDate *startTime) {
        return [[BugsnagPerformanceSpan alloc] initWithSpan:
                tracer_.startViewLoadedSpan(viewType, name, startTime.timeIntervalSinceReferenceDate)];
    }

    void reportNetworkRequestSpan(NSURLSessionTask * task, NSURLSessionTaskMetrics *metrics) {
        tracer_.reportNetworkSpan(task, metrics);
    }


private:
    NSArray<Task> *buildInitialTasks();
    NSArray<Task> *buildRecurringTasks();

    bool started_;
    std::shared_ptr<Batch> batch_;
    Tracer tracer_;
    Worker *worker_;
    std::mutex mutex_;
};
}
