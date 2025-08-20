//
//  BugsnagPerformanceAppStartTypePlugin.mm
//  BugsnagPerformance
//
//  Created by Daria Bialobrzeska on 18/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "SpanStackingHandler.h"
#import <BugsnagPerformance/BugsnagPerformanceSpanControl.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanQuery.h>
#import <BugsnagPerformance/BugsnagPerformancePluginContext.h>
#import <BugsnagPerformance/BugsnagPerformanceAppStartSpanControl.h>
#import "BugsnagPerformanceAppStartSpanControl+Private.h"
#import "BugsnagPerformanceAppStartTypePlugin.h"
#import "BugsnagPerformanceCrossTalkAPI.h"

@interface BugsnagPerformanceAppStartTypePlugin()
@property(nonatomic) std::shared_ptr<SpanStackingHandler> spanStackingHandler;
@end

@implementation BugsnagPerformanceAppStartTypePlugin

- (instancetype)initWithSpanStackingHandler:(std::shared_ptr<SpanStackingHandler>)spanStackingHandler {
    if ((self = [super init])) {
        _spanStackingHandler = spanStackingHandler;
    }
    return self;
}

#pragma mark BugsnagPerformancePlugin

- (void)installWithContext:(BugsnagPerformancePluginContext *)context {
    [context addSpanControlProvider:self];
}

- (void)start {
}

#pragma mark BugsnagPerformanceSpanControlProvider

- (__nullable id<BugsnagPerformanceSpanControl>)getSpanControlsWithQuery:(BugsnagPerformanceSpanQuery *)query {
    if ([query isKindOfClass:[BugsnagPerformanceAppStartSpanControl class]]) {
        @synchronized (self) {
            if (self.spanStackingHandler == nullptr) {
                return nil;
            }

            BugsnagPerformanceSpan *appStartSpan = self.spanStackingHandler->findSpanForCategory(@"app_start");
            if (appStartSpan == nil) {
                return nil;
            }
            return [[BugsnagPerformanceAppStartSpanControl alloc] initWithSpan:appStartSpan];
        }
    }
    return nil;
}
@end
