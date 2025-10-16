//
//  ViewLoadSpanFactoryCallbacks.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import "../../Span/BugsnagPerformanceSpan+Private.h"

typedef BugsnagPerformanceSpan *_Nullable(^GetViewLoadParentSpanCallback)(void);
typedef BOOL (^IsViewLoadInProgressCallback)(void);
typedef void (^OnViewLoadSpanStarted)(NSString * _Nonnull);

@interface ViewLoadSpanFactoryCallbacks: NSObject

@property (nonatomic, nullable) GetViewLoadParentSpanCallback getViewLoadParentSpan;
@property (nonatomic, nullable) IsViewLoadInProgressCallback isViewLoadInProgress;
@property (nonatomic, nullable) OnViewLoadSpanStarted onViewLoadSpanStarted;

@end
