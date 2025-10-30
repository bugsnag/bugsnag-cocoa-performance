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
#import "SpanOptions.h"
#import "BugsnagPerformanceSpanCondition+Private.h"

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

typedef void (^SpanLifecycleCallback)(BugsnagPerformanceSpan * _Nonnull);
typedef BugsnagPerformanceSpanCondition *_Nullable(^SpanBlockedCallback)(BugsnagPerformanceSpan * _Nonnull, NSTimeInterval timeout);

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceSpan ()

@property(nonatomic, copy) void (^onDumped)(SpanId);

// These mark the actual times that the span was instantiated and ended,
// irrespective of any time values this span will report.
// We need this because we're recording metrics data in spans instead of metrics.
@property (nonatomic) CFAbsoluteTime actuallyStartedAt;
@property (nonatomic) CFAbsoluteTime actuallyEndedAt;

@property (nonatomic) CFAbsoluteTime startAbsTime;
@property (nonatomic) CFAbsoluteTime endAbsTime;
@property (nonatomic) BOOL isClone;
@property (nonatomic) OnSpanDestroyAction onSpanDestroyAction;
@property (nonatomic,readwrite) NSString *name;
@property (nonatomic,readonly) NSMutableDictionary *attributes;
@property (nonatomic) SpanLifecycleCallback onSpanEndSet;
@property (nonatomic) SpanLifecycleCallback onSpanClosed;
@property (nonatomic) SpanBlockedCallback onSpanBlocked;
@property (nonatomic,readwrite) SpanId parentId;
@property (nonatomic) double samplingProbability;
@property (nonatomic) BSGTriState firstClass;
@property (nonatomic) SpanKind kind;
@property (nonatomic,readwrite) BOOL isMutable;
@property (nonatomic,readwrite) BOOL hasBeenProcessed;
@property (nonatomic,readonly) BOOL isBlocked;
@property (nonatomic,readonly) NSUInteger attributeCountLimit;
@property (nonatomic,readwrite) BOOL wasStartOrEndTimeProvided;
@property (nonatomic) MetricsOptions metricsOptions;
@property (nonatomic, strong) FrameMetricsSnapshot *startFramerateSnapshot;
@property (nonatomic, strong) FrameMetricsSnapshot *endFramerateSnapshot;
@property (nonatomic, strong) NSMutableArray<BugsnagPerformanceSpanCondition *> *activeConditions;

@property(nonatomic) uint64_t startClock;

@property(atomic) SpanState state;

- (instancetype)initWithName:(NSString *)name
                     traceId:(TraceId) traceId
                      spanId:(SpanId) spanId
                    parentId:(SpanId) parentId
                   startTime:(CFAbsoluteTime) startTime
                  firstClass:(BSGTriState) firstClass
         samplingProbability:(double) samplingProbability
         attributeCountLimit:(NSUInteger)attributeCountLimit
              metricsOptions:(MetricsOptions) metricsOptions
                onSpanEndSet:(SpanLifecycleCallback) onSpanEndSet
                onSpanClosed:(SpanLifecycleCallback) onSpanEnded
               onSpanBlocked:(SpanBlockedCallback) onSpanBlocked NS_DESIGNATED_INITIALIZER;

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
- (void)markEndAbsoluteTime:(CFAbsoluteTime)endTime;

- (void)forceMutate:(void (^)())block;

@end

NS_ASSUME_NONNULL_END
