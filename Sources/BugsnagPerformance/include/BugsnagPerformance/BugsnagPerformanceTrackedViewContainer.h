//
//  BugsnagPerformanceTrackedViewContainer.h
//  BugsnagPerformance
//
//  Created by Robert B on 8/12/2023.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface BugsnagPerformanceTrackedViewContainer: NSProxy 

+ (id)trackViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
