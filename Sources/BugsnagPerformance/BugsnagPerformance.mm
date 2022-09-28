//
//  BugsnagPerformance.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <BugsnagPerformance/BugsnagPerformance.h>

#import "BugsnagPerformanceSpan+Private.h"
#import "Tracer.h"

#import <memory>

#define LOG_NOT_STARTED() NSLog(@"Error: %s called before +[BugsnagPerformance startWithConfiguration:]", __PRETTY_FUNCTION__)

using namespace bugsnag;

@implementation BugsnagPerformance

static std::shared_ptr<Tracer> tracer;

+ (void)startWithConfiguration:(BugsnagPerformanceConfiguration *)configuration {
    if (tracer) {
        NSLog(@"Error: %s called more than once", __PRETTY_FUNCTION__);
        return;
    }
    tracer = std::make_shared<Tracer>(configuration.endpoint);
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name {
    if (!tracer) {
        LOG_NOT_STARTED();
        return [[BugsnagPerformanceSpan alloc] initWithSpan:nil];
    }
    return [[BugsnagPerformanceSpan alloc] initWithSpan:tracer->startSpan(name, CFAbsoluteTimeGetCurrent())];
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name startTime:(NSDate *)startTime {
    if (!tracer) {
        LOG_NOT_STARTED();
        return [[BugsnagPerformanceSpan alloc] initWithSpan:nil];
    }
    return [[BugsnagPerformanceSpan alloc] initWithSpan:tracer->startSpan(name, startTime.timeIntervalSinceReferenceDate)];
}

@end
