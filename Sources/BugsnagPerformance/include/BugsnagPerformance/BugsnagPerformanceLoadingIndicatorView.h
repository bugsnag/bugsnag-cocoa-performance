//
//  BugsnagPerformanceLoadingIndicatorView.h
//  BugsnagPerformance
//
//  Created by Daria Bialobrzeska on 17/07/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "BugsnagPerformanceSpanCondition.h"

IB_DESIGNABLE
@interface BugsnagPerformanceLoadingIndicatorView : UIView

@property (nonatomic, readonly) BOOL isLoading;

- (void)finishLoading;

@end
