//
//  BugsnagPerformanceLoadingIndicatorView.m
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
    NSLog(@"[DARIA_LOG] LoadingIndicatorView initWithFrame");
    self = [super initWithFrame:frame];
    if (self)
    {
        self.conditions = [NSMutableArray array];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *) coder {
    NSLog(@"[DARIA_LOG] LoadingIndicatorView initWithCoder");
    self = [super initWithCoder:coder];
    if (self)
    {
        self.conditions = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"[DARIA_LOG] LoadingIndicatorView dealloc");
    [self endAllConditions];
}

- (void)finishLoading {
    NSLog(@"[DARIA_LOG] LoadingIndicatorView finishLoading");
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
    NSLog(@"[DARIA_LOG] LoadingIndicatorView didMoveToWindow");
    [super didMoveToWindow];

    if (self.window == nil) {
        NSLog(@"[DARIA_LOG] LoadingIndicatorView window is nil");
        // If the view is removed from the window, end all conditions.
        [self endAllConditions];
    } else {
        
        if (!self.isLoading) {
            NSLog(@"[DARIA_LOG] LoadingIndicatorView create conditions");
            self.isLoading = YES;
            NSMutableArray<BugsnagPerformanceSpanCondition*>* newConditions = BugsnagPerformanceLibrary::getBugsnagPerformanceImpl()->loadingIndicatorWasAdded(self);

            [self endAllConditions];
            self.conditions = newConditions;
            NSLog(@"[DARIA_LOG] LoadingIndicatorView new conditions counted: %d", (int)self.conditions.count);
        }
    }
}

- (void)didMoveToSuperview {
    NSLog(@"[DARIA_LOG] LoadingIndicatorView didMoveToSuperview");
    [super didMoveToSuperview];

    if (self.superview == nil) {
        NSLog(@"[DARIA_LOG] LoadingIndicatorView superview is nil");
        // If the view is removed from the superview, end all conditions.
        [self endAllConditions];
        return;
    }

    if (!self.isLoading) {
        NSLog(@"[DARIA_LOG] LoadingIndicatorView create conditions");
        self.isLoading = YES;
        NSMutableArray<BugsnagPerformanceSpanCondition*>* newConditions = BugsnagPerformanceLibrary::getBugsnagPerformanceImpl()->loadingIndicatorWasAdded(self);

        [self endAllConditions];
        self.conditions = newConditions;
        NSLog(@"[DARIA_LOG] LoadingIndicatorView new conditions counted: %d", (int)self.conditions.count);
    }
}

- (void)endAllConditions {
    NSLog(@"[DARIA_LOG] LoadingIndicatorView endAllConditions");
    for (BugsnagPerformanceSpanCondition* condition in self.conditions) {
        if (@available(iOS 13.0, *)) {
            [condition closeWithEndTime:[NSDate now]];
        } else {
            [condition closeWithEndTime:[[NSDate alloc] init]];
        }
    }
    [self.conditions removeAllObjects];
}

@end
