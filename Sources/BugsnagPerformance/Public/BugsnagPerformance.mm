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
