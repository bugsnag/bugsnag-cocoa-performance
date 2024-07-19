//
//  BugsnagPerformanceSpan.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanOptions.h>

#import "Span.h"
#import "SpanKind.h"

#import <memory>

using namespace bugsnag;

typedef enum {
    AbortOnSpanDestroy,
    EndOnSpanDestroy
} SpanDestroyAction;

typedef void (^OnSpanEnd)(BugsnagPerformanceSpan * _Nonnull span);

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceSpan ()

@property(nonatomic, copy) void (^onDumped)(BugsnagPerformanceSpan *);

@property(nonatomic) NSString *name;
@property(nonatomic) SpanId parentId;
@property(nonatomic) CFAbsoluteTime startTime;
@property(nonatomic) NSDate *startNSDate;
@property(nonatomic) CFAbsoluteTime endTime;
@property(nonatomic) NSDate *endNSDate;
@property(nonatomic) BSGFirstClass firstClass;
@property(nonatomic) OnSpanEnd onEnd;
@property(nonatomic) uint64_t startClock;
@property(nonatomic) SpanDestroyAction spanDestroyAction;
@property(nonatomic) BOOL isEnded;
@property(nonatomic) NSMutableDictionary *attributes;
@property(nonatomic) double samplingProbability;
@property(nonatomic) SpanKind kind;
@property(nonatomic,readwrite) BOOL isValid;

- (instancetype) initWithName:(NSString *)name
                      traceId:(TraceId)traceId
                       spanId:(SpanId)spanId
                     parentId:(SpanId)parentId
                    startTime:(CFAbsoluteTime)startTime
                   firstClass:(BSGFirstClass)firstClass
                        onEnd:(OnSpanEnd)onEnd NS_DESIGNATED_INITIALIZER;

- (void)addAttribute:(NSString *)attributeName withValue:(id)value;

- (void)addAttributes:(NSDictionary *)attributes;

- (BOOL)hasAttribute:(NSString *)attributeName withValue:(id)value;

- (_Nullable id)getAttribute:(NSString *)attributeName;

- (void)endWithAbsoluteTime:(CFAbsoluteTime)endTime;

- (void)updateSamplingProbability:(double)newSamplingProbability;

@end

NS_ASSUME_NONNULL_END
