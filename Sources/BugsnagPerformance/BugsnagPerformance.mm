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

@implementation BugsnagPerformance

static std::shared_ptr<Tracer> tracer;

+ (void)startWithConfiguration:(BugsnagPerformanceConfiguration *)configuration {
    NSAssert(!tracer, @"+[BugsnagPerformance startWithConfiguration:] already called");
    tracer = std::make_shared<Tracer>(configuration.endpoint);
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name {
    return [[BugsnagPerformanceSpan alloc] initWithSpan:tracer->startSpan(name, CFAbsoluteTimeGetCurrent())];
}

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name startTime:(NSDate *)startTime {
    return [[BugsnagPerformanceSpan alloc] initWithSpan:tracer->startSpan(name, startTime.timeIntervalSinceReferenceDate)];
}

@end
