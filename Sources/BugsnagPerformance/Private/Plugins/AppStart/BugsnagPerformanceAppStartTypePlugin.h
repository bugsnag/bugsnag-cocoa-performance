//
//  BugsnagPerformanceAppStartTypePlugin.h
//  BugsnagPerformance
//
//  Created by Daria Bialobrzeska on 18/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "../../Core/SpanStack/SpanStackingHandler.h"
#import <BugsnagPerformance/BugsnagPerformancePlugin.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanControlProvider.h>
#import "../../Instrumentation/Instrumentation.h"

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceAppStartTypePlugin: NSObject<BugsnagPerformancePlugin, BugsnagPerformanceSpanControlProvider>
- (void)setGetAppStartInstrumentationStateCallback:(GetAppStartInstrumentationStateSnapshot)callback;
@end

NS_ASSUME_NONNULL_END
