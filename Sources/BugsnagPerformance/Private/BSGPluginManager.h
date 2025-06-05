//
//  BSGPluginManager.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 05/06/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BugsnagPerformance/BugsnagPerformancePlugin.h>
#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import "BSGPrioritizedStore.h"
#import "SpanControl/BSGCompositeSpanControlProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface BSGPluginManager : NSObject

- (instancetype)initWithConfiguration:(BugsnagPerformanceConfiguration *)configuration
                    compositeProvider:(BSGCompositeSpanControlProvider *)compositeProvider
                 onSpanStartCallbacks:(BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> *)onSpanStartCallbacks
                   onSpanEndCallbacks:(BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> *)onSpanEndCallbacks;

- (void)installPlugins:(NSArray<id<BugsnagPerformancePlugin>> *)plugins;
- (void)startPlugins;

@end

NS_ASSUME_NONNULL_END
