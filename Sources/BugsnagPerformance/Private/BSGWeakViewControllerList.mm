//
//  BSGWeakViewControllerList.m
//  BugsnagPerformance-iOS
//
//  Created by Robert B on 13/02/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "BSGWeakViewControllerList.h"
#import <UIKit/UIKit.h>

@implementation BSGWeakViewControllerPointer

- (instancetype) initWithViewController:(UIViewController *)viewController {
    if ((self = [super init])) {
        _viewController = viewController;
    }
    return self;
}

+ (instancetype) pointerWithViewController:(UIViewController *)viewController {
    return [[BSGWeakViewControllerPointer alloc] initWithViewController:viewController];
}

@end
