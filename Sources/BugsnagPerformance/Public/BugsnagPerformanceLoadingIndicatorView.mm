//
//  LoadingIndicatorView.m
//  BugsnagPerformance
//
//  Created by Daria Bialobrzeska on 17/07/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "../Private/Logging.h"
#import "../Private/BugsnagPerformanceLibrary.h"
#import "../Private/BugsnagPerformanceSpanCondition+Private.h"
#import "../Private/BugsnagPerformanceLoadingIndicatorView+Private.h"

@interface BugsnagPerformanceLoadingIndicatorView()
@property (nonatomic, strong) NSMutableArray<BugsnagPerformanceSpanCondition *> *conditions;
@property (nonatomic, readwrite) BOOL isLoading;
@end

@implementation BugsnagPerformanceLoadingIndicatorView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self)
    {
        self.conditions = [NSMutableArray array];
        self.isLoading = YES;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *) coder {
    self = [super initWithCoder:coder];
    if (self)
    {
        self.conditions = [NSMutableArray array];
        self.isLoading = YES;
    }
    return self;
}

- (void)dealloc {
    [self didBecomeInactive];
}

#pragma mark Public interface

- (void)finishLoading {
    [self didBecomeInactive];
    self.isLoading = NO;
}

#pragma mark UIView

- (void)didMoveToWindow {
    [super didMoveToWindow];

    if (self.window == nil) {
        [self didBecomeInactive];
    }
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];

    if (self.superview == nil) {
        [self didBecomeInactive];
        return;
    }
    
    [self didBecomeActive];
}

#pragma mark Private interface

- (void)addConditions:(NSArray<BugsnagPerformanceSpanCondition *> *)conditions {
    [self.conditions addObjectsFromArray:conditions];
}

- (void)closeAllConditions {
    auto currentDate = [NSDate date];
    for (BugsnagPerformanceSpanCondition *condition in self.conditions) {
        [condition closeWithEndTime:currentDate];
    }
    [self.conditions removeAllObjects];
}

- (void)endLoadingSpan {
    [self.loadingSpan end];
}

#pragma mark Helpers

- (void)didBecomeInactive {
    if (!self.isLoading) {
        return;
    }
    [self closeAllConditions];
    [self endLoadingSpan];
}

- (void)didBecomeActive {
    if (!self.isLoading) {
        return;
    }
    BugsnagPerformanceLibrary::getBugsnagPerformanceImpl()->loadingIndicatorWasAdded(self);
}

@end
