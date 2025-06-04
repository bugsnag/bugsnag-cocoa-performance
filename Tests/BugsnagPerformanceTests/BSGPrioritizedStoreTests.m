//
//  BSGPrioritizedStoreTests.m
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/06/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
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

@end
