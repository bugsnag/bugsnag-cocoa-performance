//
//  BugsnagPerformanceSpanConditionTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Robert B on 24/01/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "BugsnagPerformanceSpanCondition+Private.h"
#import "BugsnagPerformanceSpanContext.h"

@interface BugsnagPerformanceSpanConditionTests : XCTestCase

@end

@implementation BugsnagPerformanceSpanConditionTests

#pragma mark - conditionId

- (void)testConditionsShouldHaveUniqueIds {
    __block BugsnagPerformanceSpanCondition *condition1 = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                        onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {}
                                                      onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) { return nil; }];
    __block BugsnagPerformanceSpanCondition *condition2 = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                        onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {}
                                                      onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) { return nil; }];
    __block BugsnagPerformanceSpanCondition *condition3 = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                        onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {}
                                                      onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) { return nil; }];
    
    XCTAssertNotEqual(condition1.conditionId, condition2.conditionId);
    XCTAssertNotEqual(condition1.conditionId, condition3.conditionId);
    XCTAssertNotEqual(condition2.conditionId, condition3.conditionId);
}

#pragma mark - isActive

- (void)testConditionIsInitiallyActive {
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {}
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) { return nil; }];
    XCTAssertTrue(condition.isActive);
}

- (void)testUpgradedConditionIsActive {
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {}
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) { return nil; }];
    [condition upgrade];
    XCTAssertTrue(condition.isActive);
}

- (void)testUpgradedConditionStaysActiveAfterTimeout {
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {}
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) { return nil; }];
    [condition upgrade];
    [condition didTimeout];
    XCTAssertTrue(condition.isActive);
}

- (void)testConditionIsNotActiveAfterTimeout {
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {}
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) { return nil; }];
    [condition didTimeout];
    XCTAssertFalse(condition.isActive);
}

- (void)testConditionIsNotActiveAfterCancel {
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {}
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) { return nil; }];
    [condition cancel];
    XCTAssertFalse(condition.isActive);
}

- (void)testConditionIsNotActiveAfterClose {
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {}
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) { return nil; }];
    [condition closeWithEndTime:0];
    XCTAssertFalse(condition.isActive);
}

- (void)testConditionIsNotActiveAfterCancelAndUpgrade {
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {}
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) { return nil; }];
    [condition cancel];
    [condition upgrade];
    XCTAssertFalse(condition.isActive);
}

- (void)testConditionIsNotActiveAfterCloseAndUpgrade {
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {}
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) { return nil; }];
    [condition closeWithEndTime:0];
    [condition upgrade];
    XCTAssertFalse(condition.isActive);
}

#pragma mark - closeWithEndTime

- (void)testBugsnagPerformanceSpanConditionCanBeClosedOnlyOnce {
    __block NSInteger closeCount = 0;
    __block NSInteger deactivatedCount = 0;
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *c, CFAbsoluteTime) {
        XCTAssertEqual(condition, c);
        closeCount++;
    }
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) {
        XCTFail(@"Unexpected upgrade");
        return nil;
    }];
    
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *) {
        deactivatedCount++;
    }];
    
    [condition closeWithEndTime:0];
    XCTAssertEqual(closeCount, 1);
    XCTAssertEqual(deactivatedCount, 1);
    [condition closeWithEndTime:0];
    XCTAssertEqual(closeCount, 1);
    XCTAssertEqual(deactivatedCount, 1);
}

- (void)testBugsnagPerformanceSpanConditionClosePassesTheReceivedEndTimeToTheCloseCallback {
    __block NSInteger closeCount = 0;
    CFAbsoluteTime expectedEndTime = 42;
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *c, CFAbsoluteTime endTime) {
        XCTAssertEqual(condition, c);
        XCTAssertEqual(expectedEndTime, endTime);
        closeCount++;
    }
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) {
        XCTFail(@"Unexpected upgrade");
        return nil;
    }];
    
    [condition closeWithEndTime:[NSDate dateWithTimeIntervalSinceReferenceDate:expectedEndTime]];
    XCTAssertEqual(closeCount, 1);
}

- (void)testCancelledBugsnagPerformanceSpanConditionCantBeClosed {
    __block NSInteger deactivatedCount = 0;
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {
        XCTFail(@"Unexpected close");
    }
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) {
        XCTFail(@"Unexpected upgrade");
        return nil;
    }];
    
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *) {
        deactivatedCount++;
    }];
    
    [condition cancel];
    XCTAssertEqual(deactivatedCount, 1);
    [condition closeWithEndTime:0];
    XCTAssertEqual(deactivatedCount, 1);
}

- (void)testUpgradedBugsnagPerformanceSpanConditionCanBeClosed {
    __block NSInteger closeCount = 0;
    __block NSInteger deactivatedCount = 0;
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {
        closeCount++;
    }
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) {
        return nil;
    }];
    
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *) {
        deactivatedCount++;
    }];
    
    [condition upgrade];
    XCTAssertEqual(deactivatedCount, 0);
    [condition closeWithEndTime:0];
    XCTAssertEqual(closeCount, 1);
    XCTAssertEqual(deactivatedCount, 1);
}

- (void)testCloseBugsnagPerformanceSpanConditionCallsAllDeactivationCallbacks {
    __block NSInteger deactivatedCountA = 0;
    __block NSInteger deactivatedCountB = 0;
    __block NSInteger deactivatedCountC = 0;
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {}
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) {
        return nil;
    }];
    
    __block __weak BugsnagPerformanceSpanCondition *weakCondition = condition;
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *c) {
        __strong BugsnagPerformanceSpanCondition *strongCondition = weakCondition;
        deactivatedCountA++;
        XCTAssertEqual(strongCondition, c);
    }];
    
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *c) {
        __strong BugsnagPerformanceSpanCondition *strongCondition = weakCondition;
        deactivatedCountB++;
        XCTAssertEqual(strongCondition, c);
    }];
    
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *c) {
        __strong BugsnagPerformanceSpanCondition *strongCondition = weakCondition;
        deactivatedCountC++;
        XCTAssertEqual(strongCondition, c);
    }];
    
    [condition closeWithEndTime:0];
    XCTAssertEqual(deactivatedCountA, 1);
    XCTAssertEqual(deactivatedCountB, 1);
    XCTAssertEqual(deactivatedCountC, 1);
}

#pragma mark - upgrade

- (void)testBugsnagPerformanceSpanConditionCanBeUpgradedOnlyOnce {
    __block NSInteger upgradeCount = 0;
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {
        XCTFail(@"Unexpected close");
    }
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *c) {
        XCTAssertEqual(condition, c);
        upgradeCount++;
        return nil;
    }];
    
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *) {
        XCTFail(@"Unexpected deactivate");
    }];
    
    [condition upgrade];
    XCTAssertEqual(upgradeCount, 1);
    [condition upgrade];
    XCTAssertEqual(upgradeCount, 1);
}

- (void)testClosedBugsnagPerformanceSpanConditionCantBeUpgraded {
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {}
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) {
        XCTFail(@"Unexpected upgrade");
        return nil;
    }];
    
    [condition closeWithEndTime:0];
    
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *) {
        XCTFail(@"Unexpected deactivate");
    }];
    [condition upgrade];
}

- (void)testCancelledBugsnagPerformanceSpanConditionCantBeUpgraded {
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {
        XCTFail(@"Unexpected close");
    }
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) {
        XCTFail(@"Unexpected upgrade");
        return nil;
    }];
    
    [condition cancel];
    
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *) {
        XCTFail(@"Unexpected deactivate");
    }];
    [condition upgrade];
}

- (void)testUpgradeReturnsTheValueProvidedByTheBlock {
    TraceId tid = {.value = 1};
    __block BugsnagPerformanceSpanContext *context = [[BugsnagPerformanceSpanContext alloc] initWithTraceId:tid spanId:1];
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {
        XCTFail(@"Unexpected close");
    }
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) {
        return context;
    }];
    
    XCTAssertEqual([condition upgrade], context);
}

#pragma mark - cancel

- (void)testBugsnagPerformanceSpanConditionCanBeCancelledOnlyOnce {
    __block NSInteger deactivatedCount = 0;
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {
        XCTFail(@"Unexpected close");
    }
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) {
        XCTFail(@"Unexpected upgrade");
        return nil;
    }];
    
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *) {
        deactivatedCount++;
    }];
    
    [condition cancel];
    XCTAssertEqual(deactivatedCount, 1);
    [condition cancel];
    XCTAssertEqual(deactivatedCount, 1);
}

- (void)testClosedBugsnagPerformanceSpanConditionCantBeCancelled {
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {
    }
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) {
        XCTFail(@"Unexpected upgrade");
        return nil;
    }];
    
    [condition closeWithEndTime:0];
    
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *) {
        XCTFail(@"Unexpected deactivate");
    }];
    
    [condition cancel];
}

- (void)testUpgradedBugsnagPerformanceSpanConditionCanBeCancelled {
    __block NSInteger deactivatedCount = 0;
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {
        XCTFail(@"Unexpected close");
    }
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) {
        return nil;
    }];
    
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *) {
        deactivatedCount++;
    }];
    
    [condition upgrade];
    [condition cancel];
    XCTAssertEqual(deactivatedCount, 1);
}

- (void)testCancelBugsnagPerformanceSpanConditionCallsAllDeactivationCallbacks {
    __block NSInteger deactivatedCountA = 0;
    __block NSInteger deactivatedCountB = 0;
    __block NSInteger deactivatedCountC = 0;
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {}
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) {
        return nil;
    }];
    
    __block __weak BugsnagPerformanceSpanCondition *weakCondition = condition;
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *c) {
        __strong BugsnagPerformanceSpanCondition *strongCondition = weakCondition;
        deactivatedCountA++;
        XCTAssertEqual(strongCondition, c);
    }];
    
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *c) {
        __strong BugsnagPerformanceSpanCondition *strongCondition = weakCondition;
        deactivatedCountB++;
        XCTAssertEqual(strongCondition, c);
    }];
    
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *c) {
        __strong BugsnagPerformanceSpanCondition *strongCondition = weakCondition;
        deactivatedCountC++;
        XCTAssertEqual(strongCondition, c);
    }];
    
    [condition cancel];
    XCTAssertEqual(deactivatedCountA, 1);
    XCTAssertEqual(deactivatedCountB, 1);
    XCTAssertEqual(deactivatedCountC, 1);
}

#pragma mark - didTimeout

- (void)testNotUpgradedBugsnagPerformanceSpanConditionShouldBeCancelledOnDidTimeout {
    __block NSInteger deactivatedCount = 0;
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {
        XCTFail(@"Unexpected close");
    }
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) {
        XCTFail(@"Unexpected upgrade");
        return nil;
    }];
    
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *) {
        deactivatedCount++;
    }];
    
    [condition didTimeout];
    XCTAssertEqual(deactivatedCount, 1);
}

- (void)testUpgradedBugsnagPerformanceSpanConditionShouldNotBeCancelledOnDidTimeout {
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {
        XCTFail(@"Unexpected close");
    }
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) {
        return nil;
    }];
    
    [condition upgrade];
    
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *) {
        XCTFail(@"Unexpected deactivate");
    }];
    
    [condition didTimeout];
}

- (void)testDidTimeoutBugsnagPerformanceSpanConditionCallsAllDeactivationCallbacks {
    __block NSInteger deactivatedCountA = 0;
    __block NSInteger deactivatedCountB = 0;
    __block NSInteger deactivatedCountC = 0;
    __block BugsnagPerformanceSpanCondition *condition = [BugsnagPerformanceSpanCondition conditionWithSpan:nil
                                                       onClosedCallback:^(BugsnagPerformanceSpanCondition *, CFAbsoluteTime) {}
                                                     onUpgradedCallback:^BugsnagPerformanceSpanContext *(BugsnagPerformanceSpanCondition *) {
        return nil;
    }];
    
    __block __weak BugsnagPerformanceSpanCondition *weakCondition = condition;
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *c) {
        __strong BugsnagPerformanceSpanCondition *strongCondition = weakCondition;
        deactivatedCountA++;
        XCTAssertEqual(strongCondition, c);
    }];
    
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *c) {
        __strong BugsnagPerformanceSpanCondition *strongCondition = weakCondition;
        deactivatedCountB++;
        XCTAssertEqual(strongCondition, c);
    }];
    
    [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *c) {
        __strong BugsnagPerformanceSpanCondition *strongCondition = weakCondition;
        deactivatedCountC++;
        XCTAssertEqual(strongCondition, c);
    }];
    
    [condition didTimeout];
    XCTAssertEqual(deactivatedCountA, 1);
    XCTAssertEqual(deactivatedCountB, 1);
    XCTAssertEqual(deactivatedCountC, 1);
}

@end
