//
//  ViewLoadLoadingIndicatorsHandlerCallbacks.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 26/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <UIKit/UIKit.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanCondition.h>

NS_ASSUME_NONNULL_BEGIN

typedef BugsnagPerformanceSpanCondition *_Nullable(^ LoadingIndicatorsHandlerOnLoadingCallback)(UIViewController *_Nonnull viewController);
typedef BugsnagPerformanceSpanContext *_Nullable(^ LoadingIndicatorsHandlerGetParentContextCallback)(UIViewController *_Nonnull viewController);

@interface ViewLoadLoadingIndicatorsHandlerCallbacks : NSObject

@property (nonatomic, copy) LoadingIndicatorsHandlerOnLoadingCallback onLoading;
@property (nonatomic, copy) LoadingIndicatorsHandlerGetParentContextCallback getParentContext;

@end

NS_ASSUME_NONNULL_END

