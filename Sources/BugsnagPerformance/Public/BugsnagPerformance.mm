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

+ (void)start {
    [self startWithConfiguration:[BugsnagPerformanceConfiguration loadConfig]];
}

+ (void)startWithConfiguration:(BugsnagPerformanceConfiguration *)configuration {
    getBugsnagPerformanceImpl().start(configuration);
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name {
    return getBugsnagPerformanceImpl().startSpan(name);
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name options:(BugsnagPerformanceSpanOptions *)options {
    return getBugsnagPerformanceImpl().startSpan(name, options);
}

+ (BugsnagPerformanceSpan *)startViewLoadSpanWithName:(NSString *)name viewType:(BugsnagPerformanceViewType)viewType {
    return getBugsnagPerformanceImpl().startViewLoadSpan(name, viewType);
}

+ (BugsnagPerformanceSpan *)startViewLoadSpanWithName:(NSString *)name viewType:(BugsnagPerformanceViewType)viewType options:(BugsnagPerformanceSpanOptions *)options {
    return getBugsnagPerformanceImpl().startViewLoadSpan(name, viewType, options);
}

+ (void)startViewLoadSpanWithController:(UIViewController *)controller
                                options:(BugsnagPerformanceSpanOptions *)options {
    getBugsnagPerformanceImpl().startViewLoadSpan(controller, options);
}

+ (void)endViewLoadSpanWithController:(UIViewController *)controller
                              endTime:(NSDate *)endTime {
    getBugsnagPerformanceImpl().endViewLoadSpan(controller, endTime);
}

+ (void)reportNetworkRequestSpanWithTask:(NSURLSessionTask *)task
                                 metrics:(NSURLSessionTaskMetrics *)metrics {
    getBugsnagPerformanceImpl().reportNetworkSpan(task, metrics);
}

@end
