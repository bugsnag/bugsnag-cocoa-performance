//
//  ViewLoadSpanFactoryCallbacks.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../../BugsnagPerformanceSpan+Private.h"

@interface GetViewLoadParentSpanCallbackInfo: NSObject
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *span;
@property (nonatomic) BOOL shouldBeBlocked;

+ (instancetype _Nonnull)infoWithSpan:(BugsnagPerformanceSpan *_Nullable)span
                      shouldBeBlocked:(BOOL)shouldBeBlocked;

@end

typedef GetViewLoadParentSpanCallbackInfo *_Nullable(^GetViewLoadParentSpanCallback)(void);
typedef BOOL (^IsViewLoadInProgressCallback)(void);
typedef void (^OnViewLoadSpanStarted)(NSString * _Nonnull);

@interface ViewLoadSpanFactoryCallbacks: NSObject

@property (nonatomic, nullable) GetViewLoadParentSpanCallback getViewLoadParentSpan;
@property (nonatomic, nullable) IsViewLoadInProgressCallback isViewLoadInProgress;
@property (nonatomic, nullable) OnViewLoadSpanStarted onViewLoadSpanStarted;

@end
