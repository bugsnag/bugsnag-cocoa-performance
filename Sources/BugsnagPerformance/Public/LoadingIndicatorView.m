//
//  LoadingIndicatorView.m
//  BugsnagPerformance
//
//  Created by Daria Bialobrzeska on 17/07/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadInstrumentation.h"
#import "LoadingIndicatorView.h"
#import "Logging.h"

#import <objc/runtime.h>

static const CGFloat endConditionTimeout = 0.1;
static const CGFloat conditionInitTimeout = 0.5;

@interface LoadingIndicatorView()
@property (nonatomic, strong) NSMutableArray<BugsnagPerformanceSpanCondition *> *conditions;
@property (nonatomic, readwrite) BOOL isLoading;
@end

@implementation LoadingIndicatorView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self)
    {
        self.conditions = [NSMutableArray array];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *) coder {
    self = [super initWithCoder:coder];
    if (self)
    {
        self.conditions = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc {
    [self endAllConditions];
}

- (void)finishLoading {
    if (!self.isLoading) {
        BSGLogDebug(@"LoadingIndicatorView is not loading, ignoring finishLoading call.");
        return;
    }

    // TODO track starting/stopping condition so it could be done only once
    self.isLoading = NO;
    BSGLogDebug(@"User finished loading, ending all conditions.");
    [self endAllConditions];
}


- (void)didMoveToWindow {
    [super didMoveToWindow];

    if (self.window == nil) {
        // If the view is removed from the window, end all conditions.
        [self endAllConditions];
    }
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];

    if (self.superview == nil) {
        // If the view is removed from the superview, end all conditions.
        [self endAllConditions];
        return;
    }

    if (!self.isLoading) {
        self.isLoading = YES;

        NSMutableArray<BugsnagPerformanceSpanCondition *> *newConditions = [NSMutableArray array];
        UIView *superview = self.superview;
        while (superview != nil) {
            ViewLoadInstrumentationState *associatedState = objc_getAssociatedObject(superview, &kAssociatedStateView);
            if (associatedState != nil) {
                // Start the phase

                // Block the span
                __strong BugsnagPerformanceSpan *parentSpan = [associatedState getOverallSpan];
                if (parentSpan != nil) {
                    BugsnagPerformanceSpanCondition* condition = [parentSpan blockWithTimeout:conditionInitTimeout];
                    [condition upgrade];
                    [newConditions addObject:condition];
                }
            }
            superview = superview.superview;
        }

        [self endAllConditions];
        self.conditions = newConditions;
    }
}

- (void)endAllConditions {
    for (BugsnagPerformanceSpanCondition* condition in self.conditions) {
        [condition closeWithEndTime:[NSDate dateWithTimeIntervalSinceNow:endConditionTimeout]];
    }
    [self.conditions removeAllObjects];
}

@end
