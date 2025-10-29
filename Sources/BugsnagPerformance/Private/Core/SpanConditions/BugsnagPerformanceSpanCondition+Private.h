//
//  BugsnagPerformanceSpanCondition+Private.h
//  BugsnagPerformance-iOS
//
//  Created by Robert Bartoszewski on 15/01/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceSpanCondition.h>

@class BugsnagPerformanceSpan;
@class BugsnagPerformanceSpanContext;

typedef uint64_t SpanConditionId;
typedef void (^ SpanConditionClosedCallback)(BugsnagPerformanceSpanCondition *condition, CFAbsoluteTime endTime);
typedef BugsnagPerformanceSpanContext *(^ SpanConditionUpgradedCallback)(BugsnagPerformanceSpanCondition *condition);
typedef void (^ SpanConditionDeavtivatedCallback)(BugsnagPerformanceSpanCondition *condition);

@interface BugsnagPerformanceSpanCondition ()

@property (nonatomic, readonly) SpanConditionId conditionId;
@property (nonatomic, weak) BugsnagPerformanceSpan *span;

+ (instancetype)conditionWithSpan:(BugsnagPerformanceSpan *)span
                 onClosedCallback:(SpanConditionClosedCallback)onClosedCallback
               onUpgradedCallback:(SpanConditionUpgradedCallback)onUpgradedCallback;

- (void)didTimeout;
- (void)addOnDeactivatedCallback:(SpanConditionDeavtivatedCallback)onDeactivated;

@end

