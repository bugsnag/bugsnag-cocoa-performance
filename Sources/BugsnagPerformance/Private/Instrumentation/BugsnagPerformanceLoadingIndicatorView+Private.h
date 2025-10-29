//
//  BugsnagPerformanceLoadingIndicatorView+Private.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 28/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceSpanCondition.h>
#import <BugsnagPerformance/BugsnagPerformanceLoadingIndicatorView.h>

@interface BugsnagPerformanceLoadingIndicatorView()

- (void)addCondition:(BugsnagPerformanceSpanCondition *)condition;
- (void)addConditions:(NSArray<BugsnagPerformanceSpanCondition *> *)conditions;
- (void)closeAllConditions;

@end
