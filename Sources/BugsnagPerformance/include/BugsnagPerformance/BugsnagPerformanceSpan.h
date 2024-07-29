//
//  BugsnagPerformanceSpan.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <BugsnagPerformance/BugsnagPerformanceSpanContext.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT
@interface BugsnagPerformanceSpan : BugsnagPerformanceSpanContext

@property(nonatomic,readonly) BOOL isValid;

@property (nonatomic,readonly) NSString *name;
@property (nonatomic,readonly) NSDate *_Nullable startTime;
@property (nonatomic,readonly) NSDate *_Nullable endTime;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype) initWithTraceId:(TraceId)traceId spanId:(SpanId)spanId NS_UNAVAILABLE;

- (instancetype) initWithTraceIdHi:(uint64_t)traceIdHi traceIdLo:(uint64_t)traceIdLo spanId:(SpanId)spanId NS_UNAVAILABLE;

- (void)abortIfOpen;

- (void)abortUnconditionally;

- (void)end;

- (void)endWithEndTime:(NSDate *)endTime NS_SWIFT_NAME(end(endTime:));

- (void)setAttribute:(NSString *)attributeName withValue:(_Nullable id)value;

@end

NS_ASSUME_NONNULL_END
