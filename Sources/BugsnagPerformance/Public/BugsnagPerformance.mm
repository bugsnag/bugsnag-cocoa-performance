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
    tracer.start(configuration.endpoint,
                 configuration.autoInstrumentAppStarts);
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name {
    return [[BugsnagPerformanceSpan alloc] initWithSpan:
            tracer.startSpan(name, CFAbsoluteTimeGetCurrent())];
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name startTime:(NSDate *)startTime {
    return [[BugsnagPerformanceSpan alloc] initWithSpan:
            tracer.startSpan(name, startTime.timeIntervalSinceReferenceDate)];
}

@end
