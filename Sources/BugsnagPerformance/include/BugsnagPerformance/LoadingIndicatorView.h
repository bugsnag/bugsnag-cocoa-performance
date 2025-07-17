//
//  LoadingIndicatorView.h
//  BugsnagPerformance
//
//  Created by Daria Bialobrzeska on 17/07/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "BugsnagPerformanceSpanCondition.h"

IB_DESIGNABLE
@interface LoadingIndicatorView : UIView

@property (nonatomic, strong) NSMutableArray<BugsnagPerformanceSpanCondition *> *conditions;
@property (nonatomic, readonly) BOOL isLoading;

- (id)initWithFrame:(CGRect)frame;
- (id)initWithCoder:(NSCoder *) coder;

- (void)finishLoading;

- (void)didMoveToSuperview;

- (void)didMoveToWindow;

@end
