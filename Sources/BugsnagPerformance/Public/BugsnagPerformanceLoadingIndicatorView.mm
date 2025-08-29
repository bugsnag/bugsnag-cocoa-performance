//
//  LoadingIndicatorView.m
//  BugsnagPerformance
//
//  Created by Daria Bialobrzeska on 17/07/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceLoadingIndicatorView.h>
#import "../Private/Logging.h"
#import "../Private/BugsnagPerformanceLibrary.h"

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

- (void)addCondition:(BugsnagPerformanceSpanCondition *)condition {
    [self.conditions addObject:condition];
}

- (void)addConditions:(NSArray<BugsnagPerformanceSpanCondition *> *)conditions {
    [self.conditions addObjectsFromArray:conditions];
}

- (void)closeAllConditions {
    auto currentDate = [NSDate date];
    for (BugsnagPerformanceSpanCondition* condition in self.conditions) {
        [condition closeWithEndTime:currentDate];
    }
    [self.conditions removeAllObjects];
}

#pragma mark Helpers

- (void)didBecomeInactive {
    if (!self.isLoading) {
        return;
    }
    [self closeAllConditions];
}

- (void)didBecomeActive {
    if (!self.isLoading) {
        return;
    }
    BugsnagPerformanceLibrary::getBugsnagPerformanceImpl()->loadingIndicatorWasAdded(self);
}

@end
