//
//  ViewLoadSwizzlingCallbacks.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <UIKit/UIKit.h>

typedef void (^ ViewLoadSwizzlingOriginalImplementationCallback)(void);
typedef void (^ ViewLoadSwizzlingCallback)(UIViewController *viewController, ViewLoadSwizzlingOriginalImplementationCallback originalImplementation);

@interface ViewLoadSwizzlingCallbacks : NSObject
@property (atomic, copy) ViewLoadSwizzlingCallback loadViewCallback;
@property (atomic, copy) ViewLoadSwizzlingCallback viewDidLoadCallback;
@property (atomic, copy) ViewLoadSwizzlingCallback viewWillAppearCallback;
@property (atomic, copy) ViewLoadSwizzlingCallback viewDidAppearCallback;
@property (atomic, copy) ViewLoadSwizzlingCallback viewWillLayoutSubviewsCallback;
@property (atomic, copy) ViewLoadSwizzlingCallback viewDidLayoutSubviewsCallback;
@end
