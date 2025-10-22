//
//  BSGPluginManager.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 05/06/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import <BugsnagPerformance/BugsnagPerformancePlugin.h>
#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import "../../Core/BSGPrioritizedStore.h"
#import "../../Core/PhasedStartup.h"
#import "../SpanControl/BSGCompositeSpanControlProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface BSGPluginManager : NSObject<BSGPhasedStartup>

- (instancetype)initWithSpanControlProvider:(BSGCompositeSpanControlProvider *)compositeProvider;

- (void)installPlugins:(NSArray<id<BugsnagPerformancePlugin>> *)plugins;
- (void)startPlugins;

@end

NS_ASSUME_NONNULL_END
