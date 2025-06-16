//
//  BSGPrioritizedStore.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 25/05/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "BSGPrioritizedStore.h"
#import "Utils.h"

@interface BSGPrioritizedStoreEntry: NSObject
@property (nonatomic, strong) id object;
@property (nonatomic) BugsnagPerformancePriority priority;

+ (instancetype)entryWithObject:(id)object priority:(BugsnagPerformancePriority)priority;

@end

@implementation BSGPrioritizedStoreEntry

+ (instancetype)entryWithObject:(id)object priority:(BugsnagPerformancePriority)priority {
    return [[self alloc] initWithObject:object priority:priority];
}

- (instancetype)initWithObject:(id)object priority:(BugsnagPerformancePriority)priority
{
    self = [super init];
    if (self) {
        _object = object;
        _priority = priority;
    }
    return self;
}

@end

@interface BSGPrioritizedStore ()

@property (nonatomic, strong) NSMutableArray<BSGPrioritizedStoreEntry *> *store;
@property (nonatomic, strong) NSArray *objects;

@end

@implementation BSGPrioritizedStore

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.store = [NSMutableArray array];
        self.objects = [NSArray array];
    }
    return self;
}

- (void)addObject:(id)object priority:(BugsnagPerformancePriority)priority {
    [self batchAddObjects:^(BSGPrioritizedStoreAddBlock addBlock) {
        addBlock(object, priority);
    }];
}

- (void)batchAddObjects:(BSGPrioritizedStoreBatchBlock)batchBlock {
    @synchronized (self) {
        __block __weak BSGPrioritizedStore *weakSelf = self;
        __block BOOL batchingInProgress = YES;
        __block NSMutableArray<BSGPrioritizedStoreEntry *> *temporaryStore = [NSMutableArray array];
        batchBlock(^void (id object, BugsnagPerformancePriority priority) {
            __strong BSGPrioritizedStore *strongSelf = weakSelf;
            if (!batchingInProgress) {
                BSGLogWarning(@"Ignoring an attempt to add an element after batching has finished");
                return;
            }
            NSArray *combinedStore = [strongSelf.store arrayByAddingObjectsFromArray:temporaryStore];
            for (BSGPrioritizedStoreEntry *entry in combinedStore) {
                if ([entry.object isEqual:object]) {
                    BSGLogWarning(@"Ignoring an attempt to add a duplicate element");
                    return;
                }
            }
            [temporaryStore addObject:[BSGPrioritizedStoreEntry entryWithObject:object priority:priority]];
        });
        batchingInProgress = NO;
        [self.store addObjectsFromArray:temporaryStore];
        [self sortStore];
        [self updateObjects];
    }
}

- (void)sortStore {
    [self.store sortWithOptions:NSSortStable usingComparator:^NSComparisonResult(BSGPrioritizedStoreEntry *obj1, BSGPrioritizedStoreEntry *obj2) {
        if (obj1.priority < obj2.priority) {
            return NSOrderedDescending;
        }
        if (obj1.priority > obj2.priority) {
            return NSOrderedAscending;
        }
        return NSOrderedSame;
    }];
}

- (void)updateObjects {
    NSMutableArray *newObjects = [NSMutableArray array];
    for (BSGPrioritizedStoreEntry *entry in self.store) {
        [newObjects addObject:entry.object];
    }
    self.objects = newObjects;
}

@end
