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

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceSpan ()

@property(nonatomic, copy) void (^onDumped)(BugsnagPerformanceSpan *);

- (instancetype)initWithSpan:(std::unique_ptr<bugsnag::Span>)span NS_DESIGNATED_INITIALIZER;

- (void)addAttributes:(NSDictionary *)attributes;

- (BOOL)hasAttribute:(NSString *)attributeName withValue:(id)value;

- (void)endWithAbsoluteTime:(CFAbsoluteTime)endTime;

- (SpanId)parentId;

@end

NS_ASSUME_NONNULL_END
