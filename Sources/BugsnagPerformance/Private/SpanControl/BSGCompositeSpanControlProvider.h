//
//  BSGCompositeSpanControlProvider.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/05/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpanControlProvider.h>
#import <BugsnagPerformance/BugsnagPerformancePriority.h>
#import "../BSGPrioritizedStore.h"

typedef void (^ BSGCompositeSpanControlProviderAddBlock)(id<BugsnagPerformanceSpanControlProvider> object,
                                                         BugsnagPerformancePriority priority);
typedef void (^ BSGCompositeSpanControlProviderBatchBlock)(BSGPrioritizedStoreAddBlock addBlock);

@interface BSGCompositeSpanControlProvider : NSObject <BugsnagPerformanceSpanControlProvider>

- (void)batchAddProviders:(BSGCompositeSpanControlProviderBatchBlock)addBlock;

@end
