//
//  BugsnagPerformanceAppStartTypePlugin.h
//  BugsnagPerformance
//
//  Created by Daria Bialobrzeska on 18/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "SpanStackingHandler.h"
#import <BugsnagPerformance/BugsnagPerformancePlugin.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanControlProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceAppStartTypePlugin: NSObject<BugsnagPerformancePlugin, BugsnagPerformanceSpanControlProvider>
- (instancetype)initWithSpanStackingHandler:(std::shared_ptr<SpanStackingHandler>)spanStackingHandler;
@end

NS_ASSUME_NONNULL_END
