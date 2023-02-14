//
//  BugsnagPerformance.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <BugsnagPerformance/BugsnagPerformance.h>

#import "../Private/BugsnagPerformanceImpl.h"

using namespace bugsnag;

@implementation BugsnagPerformance

static BugsnagPerformanceImpl& getImpl() {
    [[clang::no_destroy]]
    static BugsnagPerformanceImpl impl;
    return impl;
}

+ (BOOL)start:(NSError * __autoreleasing _Nullable *)error {
    auto config = [BugsnagPerformanceConfiguration loadConfig:error];
    if (config == nil) {
        return NO;
    }
    return [self startWithConfiguration:config error:error];
}

+ (BOOL)startWithConfiguration:(BugsnagPerformanceConfiguration *)configuration error:(NSError * __autoreleasing _Nullable *)error {
    if (![configuration validate:error]) {
        return NO;
    }

    return getImpl().start(configuration, error);
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name {
    return getImpl().startSpan(name);
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name startTime:(NSDate *)startTime {
    return getImpl().startSpan(name, startTime);
}

+ (BugsnagPerformanceSpan *)startViewLoadSpanWithName:(NSString *)name viewType:(BugsnagPerformanceViewType)viewType {
    return getImpl().startViewLoadSpan(name, viewType);
}

+ (BugsnagPerformanceSpan *)startViewLoadSpanWithName:(NSString *)name viewType:(BugsnagPerformanceViewType)viewType startTime:(NSDate *)startTime {
    return getImpl().startViewLoadSpan(name, viewType, startTime);
}

+ (void)startViewLoadSpanWithController:(UIViewController *)controller
                              startTime:(NSDate *)startTime {
    getImpl().startViewLoadSpan(controller, startTime);
}

+ (void)endViewLoadSpanWithController:(UIViewController *)controller
                              endTime:(NSDate *)endTime {
    getImpl().endViewLoadSpan(controller, endTime);
}

+ (void)reportNetworkRequestSpanWithTask:(NSURLSessionTask *)task
                                 metrics:(NSURLSessionTaskMetrics *)metrics {
    getImpl().reportNetworkSpan(task, metrics);
}

@end
