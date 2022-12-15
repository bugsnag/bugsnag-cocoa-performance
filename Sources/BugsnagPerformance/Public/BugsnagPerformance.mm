//
//  BugsnagPerformance.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <BugsnagPerformance/BugsnagPerformance.h>

#import "../Private/BugsnagPerformanceSpan+Private.h"
#import "../Private/Tracer.h"

using namespace bugsnag;

@implementation BugsnagPerformance

static Tracer& getTracer() {
    [[clang::no_destroy]]
    static Tracer tracer;
    return tracer;
}

+ (void)start {
    [self startWithConfiguration:[BugsnagPerformanceConfiguration loadConfig]];
}

+ (void)startWithConfiguration:(BugsnagPerformanceConfiguration *)configuration {
    [configuration validate];
    getTracer().start(configuration);
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name {
    return [[BugsnagPerformanceSpan alloc] initWithSpan:
            getTracer().startSpan(name, CFAbsoluteTimeGetCurrent())];
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name startTime:(NSDate *)startTime {
    return [[BugsnagPerformanceSpan alloc] initWithSpan:
            getTracer().startSpan(name, startTime.timeIntervalSinceReferenceDate)];
}

+ (BugsnagPerformanceSpan *)startViewLoadSpanWithName:(NSString *)name viewType:(BugsnagPerformanceViewType)viewType {
    return [[BugsnagPerformanceSpan alloc] initWithSpan:
            getTracer().startViewLoadedSpan(viewType, name, CFAbsoluteTimeGetCurrent())];
}

+ (BugsnagPerformanceSpan *)startViewLoadSpanWithName:(NSString *)name viewType:(BugsnagPerformanceViewType)viewType startTime:(NSDate *)startTime {
    return [[BugsnagPerformanceSpan alloc] initWithSpan:
            getTracer().startViewLoadedSpan(viewType, name, startTime.timeIntervalSinceReferenceDate)];
}

+ (void)reportNetworkRequestSpanWithTask:(NSURLSessionTask *)task
                                 metrics:(NSURLSessionTaskMetrics *)metrics {
    getTracer().reportNetworkSpan(task, metrics);
}

@end
