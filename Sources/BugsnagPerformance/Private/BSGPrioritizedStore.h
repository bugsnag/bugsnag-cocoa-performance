//
//  BSGPrioritizedStore.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 25/05/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformancePriority.h>

NS_ASSUME_NONNULL_BEGIN

@interface BSGPrioritizedStore<__covariant ObjectType> : NSObject

typedef void (^ BSGPrioritizedStoreAddBlock)(ObjectType object, BugsnagPerformancePriority priority);
typedef void (^ BSGPrioritizedStoreBatchBlock)(BSGPrioritizedStoreAddBlock addBlock);

// atomic: read on span start/end threads while configure() may be replacing it.
@property (atomic, readonly) NSArray<ObjectType> *objects;

- (void)addObject:(ObjectType)object priority:(BugsnagPerformancePriority)priority;
- (void)batchAddObjects:(BSGPrioritizedStoreBatchBlock)batchBlock;

@end

NS_ASSUME_NONNULL_END
