//
//  ViewLoadSpanFactoryCallbacks.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 16/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadSpanFactoryCallbacks.h"

@implementation ViewLoadSpanFactoryCallbacks
@end

@implementation GetViewLoadParentSpanCallbackInfo

+ (instancetype _Nonnull)infoWithSpan:(BugsnagPerformanceSpan *_Nullable)span
                      shouldBeBlocked:(BOOL)shouldBeBlocked {
    GetViewLoadParentSpanCallbackInfo *result = [self new];
    result.span = span;
    result.shouldBeBlocked = shouldBeBlocked;
    return result;
}

@end
