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

namespace bugsnag {
class BugsnagPerformanceImpl {
public:
    BugsnagPerformanceImpl() noexcept {};
    
    bool start(BugsnagPerformanceConfiguration *configuration, NSError **error) noexcept;
    
    void reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept {
        tracer.reportNetworkSpan(task, metrics);
    }

    BugsnagPerformanceSpan *startSpan(NSString *name) {
        return [[BugsnagPerformanceSpan alloc] initWithSpan:
                tracer.startSpan(name, CFAbsoluteTimeGetCurrent())];
    }

    BugsnagPerformanceSpan *startSpan(NSString *name, NSDate *startTime) {
        return [[BugsnagPerformanceSpan alloc] initWithSpan:
                tracer.startSpan(name, startTime.timeIntervalSinceReferenceDate)];
    }

    BugsnagPerformanceSpan *startViewLoadSpan(NSString *name, BugsnagPerformanceViewType viewType) {
        return [[BugsnagPerformanceSpan alloc] initWithSpan:
                tracer.startViewLoadedSpan(viewType, name, CFAbsoluteTimeGetCurrent())];
    }

    BugsnagPerformanceSpan *startViewLoadSpan(NSString *name, BugsnagPerformanceViewType viewType, NSDate *startTime) {
        return [[BugsnagPerformanceSpan alloc] initWithSpan:
                tracer.startViewLoadedSpan(viewType, name, startTime.timeIntervalSinceReferenceDate)];
    }

    void reportNetworkRequestSpan(NSURLSessionTask * task, NSURLSessionTaskMetrics *metrics) {
        tracer.reportNetworkSpan(task, metrics);
    }


private:
    Tracer tracer;
};
}
