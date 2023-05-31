//
//  BugsnagPerformanceSpan.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
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
@interface BugsnagPerformanceSpan : NSObject

@property(nonatomic,readonly) TraceId traceId;
@property(nonatomic,readonly) SpanId spanId;
@property(nonatomic,readonly) BOOL isValid;

- (instancetype)init NS_UNAVAILABLE;

- (void)end;

- (void)endWithEndTime:(NSDate *)endTime NS_SWIFT_NAME(end(endTime:));

@end

NS_ASSUME_NONNULL_END
