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

- (instancetype)initWithSpan:(std::shared_ptr<bugsnag::Span>)span NS_DESIGNATED_INITIALIZER;

- (void)addAttribute:(NSString *)attributeName withValue:(id)value;

- (void)addAttributes:(NSDictionary *)attributes;

- (BOOL)hasAttribute:(NSString *)attributeName withValue:(id)value;

- (id)getAttribute:(NSString *)attributeName;

- (void)endWithAbsoluteTime:(CFAbsoluteTime)endTime;

- (SpanId)parentId;
- (NSString *)name;
- (void)updateName:(NSString *)name;
- (NSDate *_Nullable)startTime;
- (NSDate *_Nullable)endTime;
- (void)updateStartTime:(NSDate *)startTime;

@end

NS_ASSUME_NONNULL_END
