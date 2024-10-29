//
//  BugsnagPerformance.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <BugsnagPerformance/BugsnagPerformance.h>

#import "../Private/BugsnagPerformanceLibrary.h"

using namespace bugsnag;

@implementation BugsnagPerformance

+ (void)start {
    [self startWithConfiguration:[BugsnagPerformanceConfiguration loadConfig]];
}

+ (void)startWithApiKey:(NSString *)apiKey {
    [self startWithConfiguration:[[BugsnagPerformanceConfiguration alloc] initWithApiKey:apiKey]];
}

+ (void)startWithConfiguration:(BugsnagPerformanceConfiguration *)configuration {
    BugsnagPerformanceLibrary::configureLibrary(configuration);
    BugsnagPerformanceLibrary::startLibrary();
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name {
    return BugsnagPerformanceLibrary::getBugsnagPerformanceImpl()->startCustomSpan(name);
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name options:(BugsnagPerformanceSpanOptions *)options {
    return BugsnagPerformanceLibrary::getBugsnagPerformanceImpl()->startCustomSpan(name, options);
}

+ (BugsnagPerformanceSpan *)startViewLoadSpanWithName:(NSString *)name viewType:(BugsnagPerformanceViewType)viewType {
    return BugsnagPerformanceLibrary::getBugsnagPerformanceImpl()->startViewLoadSpan(name, viewType);
}

+ (BugsnagPerformanceSpan *)startViewLoadSpanWithName:(NSString *)name viewType:(BugsnagPerformanceViewType)viewType options:(BugsnagPerformanceSpanOptions *)options {
    return BugsnagPerformanceLibrary::getBugsnagPerformanceImpl()->startViewLoadSpan(name, viewType, options);
}

+ (BugsnagPerformanceSpan *)startViewLoadPhaseSpanWithName:(NSString *)name
                                                     phase:(NSString *)phase
                                             parentContext:(BugsnagPerformanceSpanContext *)parentContext {
    return BugsnagPerformanceLibrary::getBugsnagPerformanceImpl()->startViewLoadPhaseSpan(name, phase, parentContext);
}

+ (void)startViewLoadSpanWithController:(UIViewController *)controller
                                options:(BugsnagPerformanceSpanOptions *)options {
    BugsnagPerformanceLibrary::getBugsnagPerformanceImpl()->startViewLoadSpan(controller, options);
}

+ (void)endViewLoadSpanWithController:(UIViewController *)controller
                              endTime:(NSDate *)endTime {
    BugsnagPerformanceLibrary::getBugsnagPerformanceImpl()->endViewLoadSpan(controller, endTime);
}

+ (void)reportNetworkRequestSpanWithTask:(NSURLSessionTask *)task
                                 metrics:(NSURLSessionTaskMetrics *)metrics {
    BugsnagPerformanceLibrary::getBugsnagPerformanceImpl()->reportNetworkSpan(task, metrics);
}

@end
