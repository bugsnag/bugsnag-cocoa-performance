//
//  BugsnagPerformanceSpan.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

#import "Span.h"

#import <memory>

using namespace bugsnag;

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceSpan ()

@property(nonatomic, copy) void (^onDumped)(BugsnagPerformanceSpan *);

@property(nonatomic) std::shared_ptr<Span> span;

@property(nonatomic) SpanState state;

- (instancetype)initWithSpan:(std::shared_ptr<bugsnag::Span>)span NS_DESIGNATED_INITIALIZER;

- (void)setAttributes:(NSDictionary *)attributes;

- (BOOL)hasAttribute:(NSString *)attributeName withValue:(id)value;

- (id)getAttribute:(NSString *)attributeName;

- (void)endWithAbsoluteTime:(CFAbsoluteTime)endTime;

- (void)endOnDestroy;

- (SpanId)parentId;
- (void)updateName:(NSString *)name;
- (void)updateStartTime:(NSDate *)startTime;

@end

NS_ASSUME_NONNULL_END
