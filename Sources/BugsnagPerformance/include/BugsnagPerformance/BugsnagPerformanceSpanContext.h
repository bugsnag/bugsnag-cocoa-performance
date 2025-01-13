//
//  BugsnagPerformanceSpanContext.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 01.07.24.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef union {
    __uint128_t value;
    struct {
        uint64_t lo;
        uint64_t hi;
    };
} TraceId;

typedef uint64_t SpanId;

OBJC_EXPORT
@interface BugsnagPerformanceSpanContext : NSObject

@property(nonatomic,readonly) TraceId traceId;
@property(nonatomic,readonly) SpanId spanId;
@property(nonatomic,readonly) uint64_t traceIdHi;
@property(nonatomic,readonly) uint64_t traceIdLo;

- (instancetype) initWithTraceId:(TraceId)traceId spanId:(SpanId)spanId;

- (instancetype) initWithTraceIdHi:(uint64_t)traceIdHi traceIdLo:(uint64_t)traceIdLo spanId:(SpanId)spanId;

@end

NS_ASSUME_NONNULL_END
