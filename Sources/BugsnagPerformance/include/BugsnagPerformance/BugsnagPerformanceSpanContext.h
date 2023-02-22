//
//  BugsnagPerformanceSpanContext.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 15.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
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
static_assert(sizeof(TraceId) == 16, "Compiler issue: TraceId was not 16 bytes long");

typedef uint64_t SpanId;
static_assert(sizeof(SpanId) == 8, "Compiler issue: SpanId was not 8 bytes long");


// https://opentelemetry.io/docs/reference/specification/trace/api/#spancontext
OBJC_EXPORT
@protocol BugsnagPerformanceSpanContext <NSObject>

@property(nonatomic,readonly) TraceId traceId;
@property(nonatomic,readonly) SpanId spanId;
@property(nonatomic,readonly) BOOL isValid;

@end

NS_ASSUME_NONNULL_END
