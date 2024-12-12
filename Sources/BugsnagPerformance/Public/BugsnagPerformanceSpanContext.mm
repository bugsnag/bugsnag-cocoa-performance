//
//  BugsnagPerformanceSpanContext.mm
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 01.07.24.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpanContext.h>

@implementation BugsnagPerformanceSpanContext

- (instancetype) initWithTraceId:(TraceId) traceId spanId:(SpanId) spanId {
    if ((self = [super init])) {
        _traceId = traceId;
        _spanId = spanId;
    }
    return self;
}

- (instancetype) initWithTraceIdHi:(uint64_t)traceIdHi traceIdLo:(uint64_t)traceIdLo spanId:(SpanId)spanId {
    return [self initWithTraceId:TraceId{.hi=traceIdHi, .lo=traceIdLo} spanId:spanId];
}

- (uint64_t) traceIdHi {
    return self.traceId.hi;
}

- (uint64_t) traceIdLo {
    return self.traceId.lo;
}

@end
