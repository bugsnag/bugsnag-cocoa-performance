//
//  BugsnagPerformanceLoadingIndicatorView.h
//  BugsnagPerformance
//
//  Created by Daria Bialobrzeska on 17/07/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT
IB_DESIGNABLE
@interface BugsnagPerformanceLoadingIndicatorView : UIView

@property (nonatomic, readonly) BOOL isLoading;
@property (nonatomic, nullable, strong) IBInspectable NSString *name;

- (void)finishLoading;

@end

NS_ASSUME_NONNULL_END
