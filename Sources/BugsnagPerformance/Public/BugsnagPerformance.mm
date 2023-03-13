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

+ (void)start {
    [self startWithConfiguration:[BugsnagPerformanceConfiguration loadConfig]];
}

+ (void)startWithConfiguration:(BugsnagPerformanceConfiguration *)configuration {
    getImpl().start(configuration);
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name {
    return getImpl().startSpan(name);
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name options:(BugsnagPerformanceSpanOptions *)options {
    return getImpl().startSpan(name, options);
}

+ (BugsnagPerformanceSpan *)startViewLoadSpanWithName:(NSString *)name viewType:(BugsnagPerformanceViewType)viewType {
    return getImpl().startViewLoadSpan(name, viewType);
}

+ (BugsnagPerformanceSpan *)startViewLoadSpanWithName:(NSString *)name viewType:(BugsnagPerformanceViewType)viewType options:(BugsnagPerformanceSpanOptions *)options {
    return getImpl().startViewLoadSpan(name, viewType, options);
}

+ (void)startViewLoadSpanWithController:(UIViewController *)controller
                                options:(BugsnagPerformanceSpanOptions *)options {
    getImpl().startViewLoadSpan(controller, options);
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
