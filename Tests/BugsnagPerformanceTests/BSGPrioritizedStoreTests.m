//
//  BSGPrioritizedStoreTests.m
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/06/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <stdatomic.h>
#import "BSGPrioritizedStore.h"

@interface BSGPrioritizedStoreTests: XCTestCase
@end

@implementation BSGPrioritizedStoreTests

- (void)testAddOneElement {
    BSGPrioritizedStore<NSString *> *store = [BSGPrioritizedStore new];
    
    [store addObject:@"1" priority:BugsnagPerformancePriorityMedium];
    
    XCTAssertEqual([store.objects count], 1);
    XCTAssertTrue([store.objects[0] isEqualToString:@"1"]);
}

- (void)testAddElementsOneByOneWithDifferentPriorities {
    BSGPrioritizedStore<NSString *> *store = [BSGPrioritizedStore new];
    
    [store addObject:@"Third" priority:BugsnagPerformancePriorityMedium];
    [store addObject:@"Eighth" priority:BugsnagPerformancePriorityLow];
    [store addObject:@"Ninth" priority:BugsnagPerformancePriorityLow];
    [store addObject:@"Fourth" priority:BugsnagPerformancePriorityMedium];
    [store addObject:@"Fifth" priority:BugsnagPerformancePriorityMedium];
    [store addObject:@"First" priority:BugsnagPerformancePriorityHigh];
    [store addObject:@"Tenth" priority:BugsnagPerformancePriorityLow];
    [store addObject:@"Sixth" priority:BugsnagPerformancePriorityMedium];
    [store addObject:@"Seventh" priority:BugsnagPerformancePriorityMedium];
    [store addObject:@"Second" priority:BugsnagPerformancePriorityHigh];
    
    XCTAssertEqual([store.objects count], 10);
    XCTAssertTrue([store.objects[0] isEqualToString:@"First"]);
    XCTAssertTrue([store.objects[1] isEqualToString:@"Second"]);
    XCTAssertTrue([store.objects[2] isEqualToString:@"Third"]);
    XCTAssertTrue([store.objects[3] isEqualToString:@"Fourth"]);
    XCTAssertTrue([store.objects[4] isEqualToString:@"Fifth"]);
    XCTAssertTrue([store.objects[5] isEqualToString:@"Sixth"]);
    XCTAssertTrue([store.objects[6] isEqualToString:@"Seventh"]);
    XCTAssertTrue([store.objects[7] isEqualToString:@"Eighth"]);
    XCTAssertTrue([store.objects[8] isEqualToString:@"Ninth"]);
    XCTAssertTrue([store.objects[9] isEqualToString:@"Tenth"]);
}

- (void)testBatchAddElementsWithDifferentPriorities {
    BSGPrioritizedStore<NSString *> *store = [BSGPrioritizedStore new];
    
    [store batchAddObjects:^(BSGPrioritizedStoreAddBlock addBlock) {
        addBlock(@"Third", BugsnagPerformancePriorityMedium);
        addBlock(@"Eighth", BugsnagPerformancePriorityLow);
        addBlock(@"Ninth", BugsnagPerformancePriorityLow);
        addBlock(@"First", BugsnagPerformancePriorityHigh);
        addBlock(@"Fourth", BugsnagPerformancePriorityMedium);
        addBlock(@"Fifth", BugsnagPerformancePriorityMedium);
        addBlock(@"Sixth", BugsnagPerformancePriorityMedium);
        addBlock(@"Tenth", BugsnagPerformancePriorityLow);
        addBlock(@"Second", BugsnagPerformancePriorityHigh);
        addBlock(@"Seventh", BugsnagPerformancePriorityMedium);
    }];
    
    XCTAssertEqual([store.objects count], 10);
    XCTAssertTrue([store.objects[0] isEqualToString:@"First"]);
    XCTAssertTrue([store.objects[1] isEqualToString:@"Second"]);
    XCTAssertTrue([store.objects[2] isEqualToString:@"Third"]);
    XCTAssertTrue([store.objects[3] isEqualToString:@"Fourth"]);
    XCTAssertTrue([store.objects[4] isEqualToString:@"Fifth"]);
    XCTAssertTrue([store.objects[5] isEqualToString:@"Sixth"]);
    XCTAssertTrue([store.objects[6] isEqualToString:@"Seventh"]);
    XCTAssertTrue([store.objects[7] isEqualToString:@"Eighth"]);
    XCTAssertTrue([store.objects[8] isEqualToString:@"Ninth"]);
    XCTAssertTrue([store.objects[9] isEqualToString:@"Tenth"]);
}

- (void)testMixedAddElementsWithDifferentPriorities {
    BSGPrioritizedStore<NSString *> *store = [BSGPrioritizedStore new];
    
    [store batchAddObjects:^(BSGPrioritizedStoreAddBlock addBlock) {
        addBlock(@"Third", BugsnagPerformancePriorityMedium);
        addBlock(@"Eighth", BugsnagPerformancePriorityLow);
        addBlock(@"Ninth", BugsnagPerformancePriorityLow);
        addBlock(@"First", BugsnagPerformancePriorityHigh);
        addBlock(@"Fourth", BugsnagPerformancePriorityMedium);
        addBlock(@"Fifth", BugsnagPerformancePriorityMedium);
        addBlock(@"Sixth", BugsnagPerformancePriorityMedium);
        addBlock(@"Tenth", BugsnagPerformancePriorityLow);
    }];
    
    [store addObject:@"Second" priority:BugsnagPerformancePriorityHigh];
    [store addObject:@"Seventh" priority:BugsnagPerformancePriorityMedium];
    
    XCTAssertEqual([store.objects count], 10);
    XCTAssertTrue([store.objects[0] isEqualToString:@"First"]);
    XCTAssertTrue([store.objects[1] isEqualToString:@"Second"]);
    XCTAssertTrue([store.objects[2] isEqualToString:@"Third"]);
    XCTAssertTrue([store.objects[3] isEqualToString:@"Fourth"]);
    XCTAssertTrue([store.objects[4] isEqualToString:@"Fifth"]);
    XCTAssertTrue([store.objects[5] isEqualToString:@"Sixth"]);
    XCTAssertTrue([store.objects[6] isEqualToString:@"Seventh"]);
    XCTAssertTrue([store.objects[7] isEqualToString:@"Eighth"]);
    XCTAssertTrue([store.objects[8] isEqualToString:@"Ninth"]);
    XCTAssertTrue([store.objects[9] isEqualToString:@"Tenth"]);
}

- (void)testUsingAddBlockAfterBatchBlockReturnsShouldNotTakeEffect {
    BSGPrioritizedStore<NSString *> *store = [BSGPrioritizedStore new];
    
    __block BSGPrioritizedStoreAddBlock capturedAddBlock;
    [store batchAddObjects:^(BSGPrioritizedStoreAddBlock addBlock) {
        capturedAddBlock = addBlock;
        addBlock(@"Third", BugsnagPerformancePriorityMedium);
        addBlock(@"Eighth", BugsnagPerformancePriorityLow);
        addBlock(@"Ninth", BugsnagPerformancePriorityLow);
        addBlock(@"First", BugsnagPerformancePriorityHigh);
        addBlock(@"Fourth", BugsnagPerformancePriorityMedium);
        addBlock(@"Fifth", BugsnagPerformancePriorityMedium);
        addBlock(@"Sixth", BugsnagPerformancePriorityMedium);
    }];
    
    XCTAssertEqual([store.objects count], 7);
    capturedAddBlock(@"ToBeIgnored", BugsnagPerformancePriorityMedium);
    XCTAssertEqual([store.objects count], 7);
    [store addObject:@"Second" priority:BugsnagPerformancePriorityHigh];
    XCTAssertEqual([store.objects count], 8);
    
    [store batchAddObjects:^(BSGPrioritizedStoreAddBlock addBlock) {
        addBlock(@"Tenth", BugsnagPerformancePriorityLow);
        capturedAddBlock(@"ToBeIgnored2", BugsnagPerformancePriorityMedium);
    }];
    
    XCTAssertEqual([store.objects count], 9);
    
    [store addObject:@"Seventh" priority:BugsnagPerformancePriorityMedium];
    
    XCTAssertEqual([store.objects count], 10);
    XCTAssertTrue([store.objects[0] isEqualToString:@"First"]);
    XCTAssertTrue([store.objects[1] isEqualToString:@"Second"]);
    XCTAssertTrue([store.objects[2] isEqualToString:@"Third"]);
    XCTAssertTrue([store.objects[3] isEqualToString:@"Fourth"]);
    XCTAssertTrue([store.objects[4] isEqualToString:@"Fifth"]);
    XCTAssertTrue([store.objects[5] isEqualToString:@"Sixth"]);
    XCTAssertTrue([store.objects[6] isEqualToString:@"Seventh"]);
    XCTAssertTrue([store.objects[7] isEqualToString:@"Eighth"]);
    XCTAssertTrue([store.objects[8] isEqualToString:@"Ninth"]);
    XCTAssertTrue([store.objects[9] isEqualToString:@"Tenth"]);
}

- (void)testAddingDuplicateElementsShouldNotTakeEffect {
    BSGPrioritizedStore<NSString *> *store = [BSGPrioritizedStore new];
    
    [store batchAddObjects:^(BSGPrioritizedStoreAddBlock addBlock) {
        addBlock(@"Third", BugsnagPerformancePriorityMedium);
        addBlock(@"Eighth", BugsnagPerformancePriorityLow);
        addBlock(@"Ninth", BugsnagPerformancePriorityLow);
        addBlock(@"Ninth", BugsnagPerformancePriorityLow);
        addBlock(@"First", BugsnagPerformancePriorityHigh);
        addBlock(@"Fourth", BugsnagPerformancePriorityMedium);
        addBlock(@"Fifth", BugsnagPerformancePriorityMedium);
        addBlock(@"Sixth", BugsnagPerformancePriorityMedium);
        addBlock(@"Ninth", BugsnagPerformancePriorityLow);
    }];
    
    XCTAssertEqual([store.objects count], 7);
    [store addObject:@"Eighth" priority:BugsnagPerformancePriorityHigh];
    XCTAssertEqual([store.objects count], 7);
    [store addObject:@"Second" priority:BugsnagPerformancePriorityHigh];
    [store addObject:@"First" priority:BugsnagPerformancePriorityHigh];
    XCTAssertEqual([store.objects count], 8);
    
    [store batchAddObjects:^(BSGPrioritizedStoreAddBlock addBlock) {
        addBlock(@"Tenth", BugsnagPerformancePriorityLow);
        addBlock(@"Ninth", BugsnagPerformancePriorityLow);
        addBlock(@"Sixth", BugsnagPerformancePriorityLow);
    }];
    
    XCTAssertEqual([store.objects count], 9);
    
    [store addObject:@"Seventh" priority:BugsnagPerformancePriorityMedium];
    
    XCTAssertEqual([store.objects count], 10);
    XCTAssertTrue([store.objects[0] isEqualToString:@"First"]);
    XCTAssertTrue([store.objects[1] isEqualToString:@"Second"]);
    XCTAssertTrue([store.objects[2] isEqualToString:@"Third"]);
    XCTAssertTrue([store.objects[3] isEqualToString:@"Fourth"]);
    XCTAssertTrue([store.objects[4] isEqualToString:@"Fifth"]);
    XCTAssertTrue([store.objects[5] isEqualToString:@"Sixth"]);
    XCTAssertTrue([store.objects[6] isEqualToString:@"Seventh"]);
    XCTAssertTrue([store.objects[7] isEqualToString:@"Eighth"]);
    XCTAssertTrue([store.objects[8] isEqualToString:@"Ninth"]);
    XCTAssertTrue([store.objects[9] isEqualToString:@"Tenth"]);
}

- (void)testBatchAddElementsWithAnExceptionShouldIgnoreTheProblematicBatch {
    BSGPrioritizedStore<NSString *> *store = [BSGPrioritizedStore new];
    
    [store batchAddObjects:^(BSGPrioritizedStoreAddBlock addBlock) {
        addBlock(@"First", BugsnagPerformancePriorityHigh);
        addBlock(@"Second", BugsnagPerformancePriorityHigh);
        addBlock(@"Third", BugsnagPerformancePriorityHigh);
    }];
    
    XCTAssertEqual([store.objects count], 3);
    XCTAssertTrue([store.objects[0] isEqualToString:@"First"]);
    XCTAssertTrue([store.objects[1] isEqualToString:@"Second"]);
    XCTAssertTrue([store.objects[2] isEqualToString:@"Third"]);
    
    @try {
        [store batchAddObjects:^(BSGPrioritizedStoreAddBlock addBlock) {
            addBlock(@"Fourth", BugsnagPerformancePriorityHigh);
            addBlock(@"Fifth", BugsnagPerformancePriorityHigh);
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:
                            @"Should prevent the elements above from being added" userInfo:nil];
        }];
    } @catch (NSException *exception) {
        // No-op
    }
    
    XCTAssertEqual([store.objects count], 3);
    XCTAssertTrue([store.objects[0] isEqualToString:@"First"]);
    XCTAssertTrue([store.objects[1] isEqualToString:@"Second"]);
    XCTAssertTrue([store.objects[2] isEqualToString:@"Third"]);
}

#pragma mark - Thread safety

- (void)testObjectsSnapshotIsImmutableAndUnaffectedByLaterAdds {
    BSGPrioritizedStore<NSString *> *store = [BSGPrioritizedStore new];
    [store addObject:@"First" priority:BugsnagPerformancePriorityHigh];

    NSArray<NSString *> *snapshot = store.objects;
    XCTAssertFalse([snapshot isKindOfClass:[NSMutableArray class]]);

    [store addObject:@"Second" priority:BugsnagPerformancePriorityHigh];

    // The earlier snapshot must stay valid and unchanged; readers iterate it
    // on span threads while configure() may be adding callbacks.
    XCTAssertEqual(snapshot.count, 1);
    XCTAssertTrue([snapshot[0] isEqualToString:@"First"]);
    XCTAssertEqual(store.objects.count, 2);
}

// Regression test for EXC_BAD_ACCESS when span start/end callbacks are read on
// one thread while configure() adds callbacks on another (objects was nonatomic
// and the previous array could be freed mid-iteration).
// Most reliable when run with Address Sanitizer or Thread Sanitizer enabled.
- (void)testConcurrentReadsWhileAddingDoNotCrash {
    BSGPrioritizedStore<NSString *> *store = [BSGPrioritizedStore new];
    const NSUInteger objectCount = 2000;
    const NSUInteger readerCount = 4;

    // atomic (not volatile): written by the writer, read by the readers.
    __block atomic_bool writerFinished = false;
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);

    dispatch_group_async(group, queue, ^{
        for (NSUInteger i = 0; i < objectCount; i++) {
            BugsnagPerformancePriority priority = BugsnagPerformancePriorityLow;
            if (i % 3 == 0) {
                priority = BugsnagPerformancePriorityHigh;
            } else if (i % 3 == 1) {
                priority = BugsnagPerformancePriorityMedium;
            }
            [store addObject:[NSString stringWithFormat:@"%lu", (unsigned long)i] priority:priority];
        }
        atomic_store_explicit(&writerFinished, true, memory_order_release);
    });

    for (NSUInteger r = 0; r < readerCount; r++) {
        dispatch_group_async(group, queue, ^{
            NSUInteger lastCount = 0;
            // do-while: every reader reads at least once, even if the writer
            // finishes before this block is scheduled.
            do {
                NSArray<NSString *> *snapshot = store.objects;
                NSUInteger seen = 0;
                for (NSString *obj in snapshot) {
                    // Touch each element so a freed array/element would fault.
                    seen += obj.length > 0 ? 1 : 0;
                }
                XCTAssertEqual(seen, snapshot.count);
                // Snapshots only ever grow.
                XCTAssertGreaterThanOrEqual(snapshot.count, lastCount);
                lastCount = snapshot.count;
            } while (!atomic_load_explicit(&writerFinished, memory_order_acquire));
        });
    }

    long result = dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 60 * NSEC_PER_SEC));
    XCTAssertEqual(result, 0, @"Concurrent readers/writer did not finish in time");
    XCTAssertEqual(store.objects.count, objectCount);
}

@end
