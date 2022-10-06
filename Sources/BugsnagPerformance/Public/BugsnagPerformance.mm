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
    tracer.start(configuration.endpoint);
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name {
    auto span = tracer.startSpan(name, CFAbsoluteTimeGetCurrent());
    return [[BugsnagPerformanceSpan alloc] initWithSpan:span];
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name startTime:(NSDate *)startTime {
    auto span = tracer.startSpan(name, startTime.timeIntervalSinceReferenceDate);
    return [[BugsnagPerformanceSpan alloc] initWithSpan:span];
}

@end
