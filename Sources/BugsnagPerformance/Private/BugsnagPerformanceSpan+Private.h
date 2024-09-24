//
//  BugsnagPerformanceSpan.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceSpanOptions.h>
#import "BugsnagPerformanceSpanContext+Private.h"
#import "SpanKind.h"
#import "FrameRateMetrics/FrameMetricsSnapshot.h"

#import <memory>

using namespace bugsnag;

typedef enum {
    OnSpanDestroyEnd = 1,
    OnSpanDestroyAbort = 2,
} OnSpanDestroyAction;

typedef enum {
    SpanStateOpen = 1,
    SpanStateEnded = 2,
    SpanStateAborted = 3,
} SpanState;

typedef void (^OnSpanClosed)(BugsnagPerformanceSpan * _Nonnull);

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceSpan ()

@property(nonatomic, copy) void (^onDumped)(BugsnagPerformanceSpan *);

@property (nonatomic) CFAbsoluteTime startAbsTime;
@property (nonatomic) CFAbsoluteTime endAbsTime;
@property (nonatomic) OnSpanDestroyAction onSpanDestroyAction;
@property (nonatomic,readwrite) NSString *name;
@property (nonatomic,readonly) NSMutableDictionary *attributes;
@property (nonatomic) OnSpanClosed onSpanClosed;
@property (nonatomic,readwrite) SpanId parentId;
@property (nonatomic) double samplingProbability;
@property (nonatomic) BSGFirstClass firstClass;
@property (nonatomic) SpanKind kind;
@property (nonatomic,readwrite) BOOL isMutable;
@property (nonatomic,readonly) NSUInteger attributeCountLimit;
@property (nonatomic,readwrite) BOOL wasEndedWithEndTime;
@property (nonatomic, strong) FrameMetricsSnapshot *startFramerateSnapshot;
@property (nonatomic, strong) FrameMetricsSnapshot *endFramerateSnapshot;



@property(nonatomic) uint64_t startClock;

@property(atomic) SpanState state;

- (instancetype)initWithName:(NSString *)name
                     traceId:(TraceId) traceId
                      spanId:(SpanId) spanId
                    parentId:(SpanId) parentId
                   startTime:(CFAbsoluteTime) startTime
                  firstClass:(BSGFirstClass) firstClass
         attributeCountLimit:(NSUInteger)attributeCountLimit
                onSpanClosed:(OnSpanClosed) onSpanEnded NS_DESIGNATED_INITIALIZER;

- (void)internalSetAttribute:(NSString *)attributeName withValue:(_Nullable id)value;
- (void)internalSetMultipleAttributes:(NSDictionary *)attributes;

- (BOOL)hasAttribute:(NSString *)attributeName withValue:(id)value;

- (_Nullable id)getAttribute:(NSString *)attributeName;

- (void)endWithAbsoluteTime:(CFAbsoluteTime)endTime;

- (void)endOnDestroy;

- (SpanId)parentId;
- (void)updateName:(NSString *)name;
- (void)updateStartTime:(NSDate *)startTime;
- (void)updateSamplingProbability:(double) value;

@end

NS_ASSUME_NONNULL_END
