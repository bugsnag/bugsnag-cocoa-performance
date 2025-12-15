//
//  BugsnagPerformanceSpanContext+Private.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 12.08.24.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

#pragma once

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceSpanContext ()

+ (BugsnagPerformanceSpanContext*)defaultContext;

- (NSString *)encodedAsTraceParentWithSampled:(BOOL)sampled;
- (SpanId)parentId;
- (BOOL)isParentOf:(BugsnagPerformanceSpanContext *)other;

@end

NS_ASSUME_NONNULL_END
