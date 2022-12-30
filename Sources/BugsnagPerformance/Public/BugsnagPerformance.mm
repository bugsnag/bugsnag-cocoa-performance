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

    getTracer().start(configuration);
    return YES;
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
