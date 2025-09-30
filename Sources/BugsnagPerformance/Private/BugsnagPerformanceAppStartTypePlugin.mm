//
//  BugsnagPerformanceAppStartTypePlugin.mm
//  BugsnagPerformance
//
//  Created by Daria Bialobrzeska on 18/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "SpanStackingHandler.h"
#import <BugsnagPerformance/BugsnagPerformanceSpanControl.h>
#import <BugsnagPerformance/BugsnagPerformanceAppStartSpanQuery.h>
#import <BugsnagPerformance/BugsnagPerformancePluginContext.h>
#import <BugsnagPerformance/BugsnagPerformanceAppStartSpanControl.h>
#import "BugsnagPerformanceAppStartSpanControl+Private.h"
#import "BugsnagPerformanceAppStartTypePlugin.h"
#import "BugsnagPerformanceCrossTalkAPI.h"

@interface BugsnagPerformanceAppStartTypePlugin()
@property (nonatomic) GetAppStartInstrumentationStateSnapshot getAppStartInstrumentationState;
@end

@implementation BugsnagPerformanceAppStartTypePlugin

- (void)setGetAppStartInstrumentationStateCallback:(GetAppStartInstrumentationStateSnapshot)callback {
    @synchronized (self) {
        self.getAppStartInstrumentationState = callback;
    }
}

#pragma mark BugsnagPerformancePlugin

- (void)installWithContext:(BugsnagPerformancePluginContext *)context {
    [context addSpanControlProvider:self];
}

- (void)start {
}

#pragma mark BugsnagPerformanceSpanControlProvider

- (__nullable id<BugsnagPerformanceSpanControl>)getSpanControlsWithQuery:(BugsnagPerformanceSpanQuery *)query {
    if ([query isKindOfClass:[BugsnagPerformanceAppStartSpanQuery class]]) {
        @synchronized (self) {
            if (self.getAppStartInstrumentationState == nullptr) {
                return nil;
            }

            BugsnagPerformanceSpan *appStartSpan;
            AppStartupInstrumentationStateSnapshot *snapshot = self.getAppStartInstrumentationState();
            if (snapshot.isInProgress) {
                appStartSpan = snapshot.appStartSpan;
            }
            if (appStartSpan == nil) {
                return nil;
            }
            return [[BugsnagPerformanceAppStartSpanControl alloc] initWithSpan:appStartSpan];
        }
    }
    return nil;
}
@end
