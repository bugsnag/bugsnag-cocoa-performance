//
//  BugsnagPerformanceNamedSpansPlugin.h
//  BugsnagPerformanceNamedSpans
//
//  Created by Yousif Ahmed on 22/07/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//
#import <BugsnagPerformance/BugsnagPerformancePlugin.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanControlProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceNamedSpansPlugin: NSObject <BugsnagPerformancePlugin, BugsnagPerformanceSpanControlProvider>

@end

NS_ASSUME_NONNULL_END
