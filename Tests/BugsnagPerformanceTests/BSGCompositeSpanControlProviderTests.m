//
//  BSGCompositeSpanControlProviderTests.m
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/06/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BSGCompositeSpanControlProvider.h"

@interface BSGCompositeSpanControlProviderTests: XCTestCase
@end

@interface FakeSpanControl1 : NSObject<BugsnagPerformanceSpanControl>
@end

@interface FakeSpanControl2 : NSObject<BugsnagPerformanceSpanControl>
@end

@interface FakeSpanControlProvider : NSObject<BugsnagPerformanceSpanControlProvider>
@property (nonatomic, strong) id<BugsnagPerformanceSpanControl> result;
@property (nonatomic, strong) BugsnagPerformanceSpanQuery *query;
@end

@implementation FakeSpanControl1
@end

@implementation FakeSpanControl2
@end

@implementation FakeSpanControlProvider
- (id<BugsnagPerformanceSpanControl>)getSpanControlsWithQuery:(BugsnagPerformanceSpanQuery *)query {
    self.query = query;
    return self.result;
}
@end

@implementation BSGCompositeSpanControlProviderTests

- (void)testWithSingleProviderReturningNil {
    FakeSpanControlProvider *fakeProvider = [FakeSpanControlProvider new];
    BSGCompositeSpanControlProvider *provider = [BSGCompositeSpanControlProvider new];
    [provider batchAddProviders:^(BSGPrioritizedStoreAddBlock addBlock) {
        addBlock(fakeProvider, BugsnagPerformancePriorityMedium);
    }];
    
    BugsnagPerformanceSpanQuery *query = [BugsnagPerformanceSpanQuery queryWithResultType:[FakeSpanControl1 class]];
    
    XCTAssertNil([provider getSpanControlsWithQuery:query]);
    XCTAssertIdentical(fakeProvider.query, query);
}

- (void)testWithSingleProviderReturningWrongType {
    FakeSpanControlProvider *fakeProvider = [FakeSpanControlProvider new];
    fakeProvider.result = [FakeSpanControl2 new];
    BSGCompositeSpanControlProvider *provider = [BSGCompositeSpanControlProvider new];
    [provider batchAddProviders:^(BSGPrioritizedStoreAddBlock addBlock) {
        addBlock(fakeProvider, BugsnagPerformancePriorityMedium);
    }];
    
    BugsnagPerformanceSpanQuery *query = [BugsnagPerformanceSpanQuery queryWithResultType:[FakeSpanControl1 class]];
    
    XCTAssertNil([provider getSpanControlsWithQuery:query]);
    XCTAssertIdentical(fakeProvider.query, query);
}

- (void)testWithSingleProviderReturningCorrectType {
    FakeSpanControlProvider *fakeProvider = [FakeSpanControlProvider new];
    fakeProvider.result = [FakeSpanControl1 new];
    BSGCompositeSpanControlProvider *provider = [BSGCompositeSpanControlProvider new];
    [provider batchAddProviders:^(BSGPrioritizedStoreAddBlock addBlock) {
        addBlock(fakeProvider, BugsnagPerformancePriorityMedium);
    }];
    
    BugsnagPerformanceSpanQuery *query = [BugsnagPerformanceSpanQuery queryWithResultType:[FakeSpanControl1 class]];
    
    XCTAssertIdentical(fakeProvider.result, [provider getSpanControlsWithQuery:query]);
    XCTAssertIdentical(fakeProvider.query, query);
}

- (void)testWithMultipleProvidersReturningNil {
    FakeSpanControlProvider *fakeProvider1 = [FakeSpanControlProvider new];
    FakeSpanControlProvider *fakeProvider2 = [FakeSpanControlProvider new];
    FakeSpanControlProvider *fakeProvider3 = [FakeSpanControlProvider new];
    
    BSGCompositeSpanControlProvider *provider = [BSGCompositeSpanControlProvider new];
    [provider batchAddProviders:^(BSGPrioritizedStoreAddBlock addBlock) {
        addBlock(fakeProvider1, BugsnagPerformancePriorityMedium);
        addBlock(fakeProvider2, BugsnagPerformancePriorityMedium);
        addBlock(fakeProvider3, BugsnagPerformancePriorityMedium);
    }];
    
    BugsnagPerformanceSpanQuery *query = [BugsnagPerformanceSpanQuery queryWithResultType:[FakeSpanControl1 class]];
    
    XCTAssertNil([provider getSpanControlsWithQuery:query]);
    XCTAssertIdentical(fakeProvider1.query, query);
    XCTAssertIdentical(fakeProvider2.query, query);
    XCTAssertIdentical(fakeProvider3.query, query);
}

- (void)testWithMultipleProvidersReturningWrongType {
    FakeSpanControlProvider *fakeProvider1 = [FakeSpanControlProvider new];
    fakeProvider1.result = [FakeSpanControl2 new];
    FakeSpanControlProvider *fakeProvider2 = [FakeSpanControlProvider new];
    fakeProvider2.result = [FakeSpanControl2 new];
    FakeSpanControlProvider *fakeProvider3 = [FakeSpanControlProvider new];
    fakeProvider3.result = [FakeSpanControl2 new];
    
    BSGCompositeSpanControlProvider *provider = [BSGCompositeSpanControlProvider new];
    [provider batchAddProviders:^(BSGPrioritizedStoreAddBlock addBlock) {
        addBlock(fakeProvider1, BugsnagPerformancePriorityMedium);
        addBlock(fakeProvider2, BugsnagPerformancePriorityMedium);
        addBlock(fakeProvider3, BugsnagPerformancePriorityMedium);
    }];
    
    BugsnagPerformanceSpanQuery *query = [BugsnagPerformanceSpanQuery queryWithResultType:[FakeSpanControl1 class]];
    
    XCTAssertNil([provider getSpanControlsWithQuery:query]);
    XCTAssertIdentical(fakeProvider1.query, query);
    XCTAssertIdentical(fakeProvider2.query, query);
    XCTAssertIdentical(fakeProvider3.query, query);
}

- (void)testWithMultipleProvidersFirstReturningCorrectType {
    FakeSpanControlProvider *fakeProvider1 = [FakeSpanControlProvider new];
    fakeProvider1.result = [FakeSpanControl1 new];
    FakeSpanControlProvider *fakeProvider2 = [FakeSpanControlProvider new];
    fakeProvider2.result = [FakeSpanControl2 new];
    FakeSpanControlProvider *fakeProvider3 = [FakeSpanControlProvider new];
    fakeProvider3.result = [FakeSpanControl2 new];
    
    BSGCompositeSpanControlProvider *provider = [BSGCompositeSpanControlProvider new];
    [provider batchAddProviders:^(BSGPrioritizedStoreAddBlock addBlock) {
        addBlock(fakeProvider2, BugsnagPerformancePriorityMedium);
        addBlock(fakeProvider3, BugsnagPerformancePriorityMedium);
        addBlock(fakeProvider1, BugsnagPerformancePriorityHigh);
    }];
    
    BugsnagPerformanceSpanQuery *query = [BugsnagPerformanceSpanQuery queryWithResultType:[FakeSpanControl1 class]];
    
    XCTAssertIdentical(fakeProvider1.result, [provider getSpanControlsWithQuery:query]);
    XCTAssertIdentical(fakeProvider1.query, query);
    XCTAssertNil(fakeProvider2.query);
    XCTAssertNil(fakeProvider3.query);
}

- (void)testWithMultipleProvidersSecondReturningCorrectType {
    FakeSpanControlProvider *fakeProvider1 = [FakeSpanControlProvider new];
    fakeProvider1.result = [FakeSpanControl2 new];
    FakeSpanControlProvider *fakeProvider2 = [FakeSpanControlProvider new];
    fakeProvider2.result = [FakeSpanControl1 new];
    FakeSpanControlProvider *fakeProvider3 = [FakeSpanControlProvider new];
    fakeProvider3.result = [FakeSpanControl2 new];
    
    BSGCompositeSpanControlProvider *provider = [BSGCompositeSpanControlProvider new];
    [provider batchAddProviders:^(BSGPrioritizedStoreAddBlock addBlock) {
        addBlock(fakeProvider3, BugsnagPerformancePriorityLow);
        addBlock(fakeProvider2, BugsnagPerformancePriorityMedium);
        addBlock(fakeProvider1, BugsnagPerformancePriorityHigh);
    }];
    
    BugsnagPerformanceSpanQuery *query = [BugsnagPerformanceSpanQuery queryWithResultType:[FakeSpanControl1 class]];
    
    XCTAssertIdentical(fakeProvider2.result, [provider getSpanControlsWithQuery:query]);
    XCTAssertIdentical(fakeProvider1.query, query);
    XCTAssertIdentical(fakeProvider2.query, query);
    XCTAssertNil(fakeProvider3.query);
}

- (void)testWithMultipleProvidersThirdReturningCorrectType {
    FakeSpanControlProvider *fakeProvider1 = [FakeSpanControlProvider new];
    fakeProvider1.result = [FakeSpanControl2 new];
    FakeSpanControlProvider *fakeProvider2 = [FakeSpanControlProvider new];
    FakeSpanControlProvider *fakeProvider3 = [FakeSpanControlProvider new];
    fakeProvider3.result = [FakeSpanControl1 new];
    
    BSGCompositeSpanControlProvider *provider = [BSGCompositeSpanControlProvider new];
    [provider batchAddProviders:^(BSGPrioritizedStoreAddBlock addBlock) {
        addBlock(fakeProvider1, BugsnagPerformancePriorityMedium);
        addBlock(fakeProvider2, BugsnagPerformancePriorityMedium);
        addBlock(fakeProvider3, BugsnagPerformancePriorityMedium);
    }];
    
    BugsnagPerformanceSpanQuery *query = [BugsnagPerformanceSpanQuery queryWithResultType:[FakeSpanControl1 class]];
    
    XCTAssertIdentical(fakeProvider3.result, [provider getSpanControlsWithQuery:query]);
    XCTAssertIdentical(fakeProvider1.query, query);
    XCTAssertIdentical(fakeProvider2.query, query);
    XCTAssertIdentical(fakeProvider3.query, query);
}

@end
