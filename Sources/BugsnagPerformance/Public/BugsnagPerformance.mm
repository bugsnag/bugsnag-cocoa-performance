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

static Tracer tracer;

+ (void)start {
    [self startWithConfiguration:[BugsnagPerformanceConfiguration loadConfig]];
}

+ (void)startWithConfiguration:(BugsnagPerformanceConfiguration *)configuration {
    tracer.start(configuration);
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name {
    return [[BugsnagPerformanceSpan alloc] initWithSpan:
            tracer.startSpan(name, CFAbsoluteTimeGetCurrent())];
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name startTime:(NSDate *)startTime {
    return [[BugsnagPerformanceSpan alloc] initWithSpan:
            tracer.startSpan(name, startTime.timeIntervalSinceReferenceDate)];
}

+ (BugsnagPerformanceSpan *)startViewLoadSpanWithName:(NSString *)name viewType:(BugsnagPerformanceViewType)viewType {
    return [[BugsnagPerformanceSpan alloc] initWithSpan:
            tracer.startViewLoadedSpan(viewType, name, CFAbsoluteTimeGetCurrent())];
}

+ (BugsnagPerformanceSpan *)startViewLoadSpanWithName:(NSString *)name viewType:(BugsnagPerformanceViewType)viewType startTime:(NSDate *)startTime {
    return [[BugsnagPerformanceSpan alloc] initWithSpan:
            tracer.startViewLoadedSpan(viewType, name, startTime.timeIntervalSinceReferenceDate)];
}

+ (void)reportNetworkRequestSpanWithTask:(NSURLSessionTask *)task
                                 metrics:(NSURLSessionTaskMetrics *)metrics {
    return [[BugsnagPerformanceSpan alloc] initWithSpan:
            tracer.startNetworkSpan(task, metrics)];
}

@end
