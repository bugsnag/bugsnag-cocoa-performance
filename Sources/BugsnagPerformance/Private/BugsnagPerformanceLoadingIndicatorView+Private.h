//
//  BugsnagPerformanceLoadingIndicatorView+Private.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 28/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpanCondition.h>
#import <BugsnagPerformance/BugsnagPerformanceLoadingIndicatorView.h>
#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

@interface BugsnagPerformanceLoadingIndicatorView()

@property (nonatomic, strong) BugsnagPerformanceSpan *loadingSpan;

- (void)addConditions:(NSArray<BugsnagPerformanceSpanCondition *> *)conditions;
- (void)closeAllConditions;
- (void)setLoadingSpan:(BugsnagPerformanceSpan *)loadingSpan;
- (void)endLoadingSpan;

@end
