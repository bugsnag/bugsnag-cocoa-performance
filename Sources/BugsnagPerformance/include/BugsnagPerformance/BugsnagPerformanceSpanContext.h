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

typedef uint64_t SpanId;


// https://opentelemetry.io/docs/reference/specification/trace/api/#spancontext
OBJC_EXPORT
@protocol BugsnagPerformanceSpanContext <NSObject>

@property(nonatomic,readonly) TraceId traceId;
@property(nonatomic,readonly) SpanId spanId;
@property(nonatomic,readonly) BOOL isValid;

@end

NS_ASSUME_NONNULL_END
