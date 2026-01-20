//
//  BugsnagPerformanceSpanContext.mm
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 01.07.24.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpanContext.h>
#import "../Private/BugsnagPerformanceSpanContext+Private.h"
#import "../Private/SpanContext.h"

@implementation BugsnagPerformanceSpanContext

+ (BugsnagPerformanceSpanContext*)defaultContext {
    return bugsnag::getDefaultSpanContext();
}

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

- (NSString *)encodedAsTraceParent {
    return [self encodedAsTraceParentWithSampled:YES];
}

- (NSString *)encodedAsTraceParentWithSampled:(BOOL)sampled {
    return [NSString stringWithFormat:@"00-%016llx%016llx-%016llx-0%d", self.traceIdHi, self.traceIdLo, self.spanId, sampled];
}

- (uint64_t) traceIdHi {
    return self.traceId.hi;
}

- (uint64_t) traceIdLo {
    return self.traceId.lo;
}

- (SpanId)parentId {
    return 0;
}

- (BOOL)isParentOf:(BugsnagPerformanceSpanContext *)other {
    return other.parentId == self.spanId && other.traceIdHi == self.traceIdHi && other.traceIdLo == self.traceIdLo;
}

@end
