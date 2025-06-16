//
//  BugsnagPerformancePluginContext+Private.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 03/06/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformancePluginContext.h>
#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import "SpanControl/BSGCompositeSpanControlProvider.h"

typedef void (^ AddStartSpanCallbackBlock)(BugsnagPerformanceSpanStartCallback object, BugsnagPerformancePriority priority);

typedef void (^ AddEndSpanCallbackBlock)(BugsnagPerformanceSpanEndCallback object, BugsnagPerformancePriority priority);

@interface BugsnagPerformancePluginContext ()

- (instancetype)initWithConfiguration:(BugsnagPerformanceConfiguration *)configuration
          addSpanControlProviderBlock:(AddSpanControlProviderBlock)addSpanControlProviderBlock
                    addSpanStartBlock:(AddStartSpanCallbackBlock)addSpanStartBlock
                      addSpanEndBlock:(AddEndSpanCallbackBlock)addSpanEndBlock;

@end
