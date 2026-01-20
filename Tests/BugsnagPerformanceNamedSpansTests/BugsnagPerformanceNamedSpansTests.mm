//
//  BugsnagPerformanceNamedSpansTests.mm
//  BugsnagPerformanceNamedSpansTests
//
//  Created by Yousif Ahmed on 22/07/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BugsnagPerformanceNamedSpansPlugin+Private.h"
#import "BugsnagPerformanceNamedSpanQuery.h"
#import <BugsnagPerformance/BugsnagPerformancePluginContext.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanQuery.h>
#import "BugsnagPerformanceSpan+Private.h"
#import "IdGenerator.h"

using namespace bugsnag;

@interface FakePluginContext : NSObject
@property (nonatomic, copy) BugsnagPerformanceSpanStartCallback spanStartCallback;
@property (nonatomic, copy) BugsnagPerformanceSpanEndCallback spanEndCallback;
@property (nonatomic, strong) NSMutableArray<id<BugsnagPerformanceSpanControlProvider>> *spanControlProviders;
- (void)addOnSpanStartCallback:(BugsnagPerformanceSpanStartCallback)callback priority:(BugsnagPerformancePriority)priority;
- (void)addOnSpanEndCallback:(BugsnagPerformanceSpanEndCallback)callback priority:(BugsnagPerformancePriority)priority;
- (void)addSpanControlProvider:(id<BugsnagPerformanceSpanControlProvider>)provider;
@end

static BugsnagPerformanceSpan *createSpan(NSString *name) {
    MetricsOptions metricsOptions;
    TraceId tid = {.value = 1};
    return [[BugsnagPerformanceSpan alloc] initWithName:name
                                                traceId:tid
                                                 spanId:IdGenerator::generateSpanId()
                                               parentId:IdGenerator::generateSpanId()
                                              startTime:SpanOptions().startTime
                                             firstClass:BSGTriStateNo
                                    samplingProbability:1.0
                                    attributeCountLimit:128
                                         metricsOptions:metricsOptions
                                 conditionsToEndOnClose:@[]
                                           onSpanEndSet:^(BugsnagPerformanceSpan * _Nonnull) {}
                                           onSpanClosed:^(BugsnagPerformanceSpan * _Nonnull) {}
                                          onSpanBlocked:^BugsnagPerformanceSpanCondition * _Nullable(BugsnagPerformanceSpan * _Nonnull, NSTimeInterval) { return nil; }
                                        onSpanCancelled:^(BugsnagPerformanceSpan * _Nonnull) {}];
}


@implementation FakePluginContext

- (instancetype)init {
    if (self = [super init]) {
        _spanControlProviders = [NSMutableArray new];
    }
    return self;
}

- (void)addOnSpanStartCallback:(BugsnagPerformanceSpanStartCallback)callback priority:(BugsnagPerformancePriority)priority {
    self.spanStartCallback = callback;
}

- (void)addOnSpanEndCallback:(BugsnagPerformanceSpanEndCallback)callback priority:(BugsnagPerformancePriority)priority {
    self.spanEndCallback = callback;
}

- (void)addSpanControlProvider:(id<BugsnagPerformanceSpanControlProvider>)provider {
    [self.spanControlProviders addObject:provider];
}

@end

@interface BugsnagPerformanceNamedSpansTests : XCTestCase
@property (nonatomic, strong) BugsnagPerformanceNamedSpansPlugin *plugin;
@property (nonatomic, strong) BugsnagPerformancePluginContext *mockContext;
@end

@implementation BugsnagPerformanceNamedSpansTests

- (void)setUp {
    [super setUp];
    self.plugin = [[BugsnagPerformanceNamedSpansPlugin alloc] initWithTimeoutInterval:0.2 sweepInterval:0.01]; // Use a short timeout for testing
    self.mockContext = (BugsnagPerformancePluginContext *)[[FakePluginContext alloc] init];
}

- (void)tearDown {
    self.plugin = nil;
    self.mockContext = nil;
    [super tearDown];
}

#pragma mark - Installation Tests

- (void)testInstallWithContext {
    [self.plugin installWithContext:self.mockContext];
    
    FakePluginContext *fakeContext = (FakePluginContext *)self.mockContext;
    XCTAssertNotNil(fakeContext.spanStartCallback);
    XCTAssertNotNil(fakeContext.spanEndCallback);
    XCTAssertEqual(fakeContext.spanControlProviders.count, 1ULL);
    XCTAssertIdentical(fakeContext.spanControlProviders.firstObject, self.plugin);
}

- (void)testStartMethod {
    // start method should not throw
    XCTAssertNoThrow([self.plugin start]);
}

#pragma mark - Span Caching Tests

- (void)testSpanStartCallbackCachesSpan {
    [self.plugin installWithContext:self.mockContext];
    
    BugsnagPerformanceSpan *span = createSpan(@"test-span");
    FakePluginContext *fakeContext = (FakePluginContext *)self.mockContext;
    
    // Simulate span start
    fakeContext.spanStartCallback(span);
    
    // Verify span is cached
    BugsnagPerformanceNamedSpanQuery *query = [BugsnagPerformanceNamedSpanQuery queryWithName:@"test-span"];
    id<BugsnagPerformanceSpanControl> result = [self.plugin getSpanControlsWithQuery:query];
    
    XCTAssertIdentical(result, span);
}

- (void)testSpanEndCallbackRemovesSpanFromCache {
    [self.plugin installWithContext:self.mockContext];
    
    BugsnagPerformanceSpan *span = createSpan(@"test-span");
    FakePluginContext *fakeContext = (FakePluginContext *)self.mockContext;
    
    // Simulate span start and end
    fakeContext.spanStartCallback(span);
    BOOL result = fakeContext.spanEndCallback(span);
    
    XCTAssertTrue(result);
    
    // Verify span is removed from cache
    BugsnagPerformanceNamedSpanQuery *query = [BugsnagPerformanceNamedSpanQuery queryWithName:@"test-span"];
    id<BugsnagPerformanceSpanControl> cachedSpan = [self.plugin getSpanControlsWithQuery:query];
    
    XCTAssertNil(cachedSpan);
}

- (void)testMultipleSpansWithSameName {
    [self.plugin installWithContext:self.mockContext];
    
    BugsnagPerformanceSpan *span1 = createSpan(@"test-span");
    BugsnagPerformanceSpan *span2 = createSpan(@"test-span");
    FakePluginContext *fakeContext = (FakePluginContext *)self.mockContext;
    
    // Start first span
    fakeContext.spanStartCallback(span1);
    
    // Start second span with same name (should replace first)
    fakeContext.spanStartCallback(span2);
    
    // Verify second span is cached
    BugsnagPerformanceNamedSpanQuery *query = [BugsnagPerformanceNamedSpanQuery queryWithName:@"test-span"];
    id<BugsnagPerformanceSpanControl> result = [self.plugin getSpanControlsWithQuery:query];
    
    XCTAssertIdentical(result, span2);
}

- (void)testSpanEndOnlyRemovesCorrectSpan {
    [self.plugin installWithContext:self.mockContext];
    
    BugsnagPerformanceSpan *span1 = createSpan(@"test-span");
    BugsnagPerformanceSpan *span2 = createSpan(@"test-span");
    FakePluginContext *fakeContext = (FakePluginContext *)self.mockContext;
    
    // Start first span
    fakeContext.spanStartCallback(span1);
    
    // Start second span with same name
    fakeContext.spanStartCallback(span2);
    
    // End first span (should not remove from cache since span2 is now cached)
    BOOL result = fakeContext.spanEndCallback(span1);
    XCTAssertTrue(result);
    
    // Verify second span is still cached
    BugsnagPerformanceNamedSpanQuery *query = [BugsnagPerformanceNamedSpanQuery queryWithName:@"test-span"];
    id<BugsnagPerformanceSpanControl> cachedSpan = [self.plugin getSpanControlsWithQuery:query];
    
    XCTAssertIdentical(cachedSpan, span2);
}

#pragma mark - Span Control Provider Tests

- (void)testGetSpanControlsWithNamedSpanQuery {
    [self.plugin installWithContext:self.mockContext];
    
    BugsnagPerformanceSpan *span = createSpan(@"my-span");
    FakePluginContext *fakeContext = (FakePluginContext *)self.mockContext;
    
    fakeContext.spanStartCallback(span);
    
    BugsnagPerformanceNamedSpanQuery *query = [BugsnagPerformanceNamedSpanQuery queryWithName:@"my-span"];
    id<BugsnagPerformanceSpanControl> result = [self.plugin getSpanControlsWithQuery:query];
    
    XCTAssertIdentical(result, span);
}

- (void)testGetSpanControlsWithNonConstantStringNamedSpanQuery {
    [self.plugin installWithContext:self.mockContext];
    
    BugsnagPerformanceSpan *span = createSpan(@"my-span");
    FakePluginContext *fakeContext = (FakePluginContext *)self.mockContext;
    
    fakeContext.spanStartCallback(span);
    NSMutableString *name = [NSMutableString string];
    [name appendString:@"my-"];
    [name appendString:@"span"];
    
    BugsnagPerformanceNamedSpanQuery *query = [BugsnagPerformanceNamedSpanQuery queryWithName:name];
    id<BugsnagPerformanceSpanControl> result = [self.plugin getSpanControlsWithQuery:query];
    
    XCTAssertIdentical(result, span);
}

- (void)testGetSpanControlsWithNonNamedSpanQuery {
    [self.plugin installWithContext:self.mockContext];
    
    BugsnagPerformanceSpan *span = createSpan(@"my-span");
    FakePluginContext *fakeContext = (FakePluginContext *)self.mockContext;
    
    fakeContext.spanStartCallback(span);
    
    BugsnagPerformanceSpanQuery *query = [BugsnagPerformanceSpanQuery queryWithResultType:[BugsnagPerformanceSpan class]];
    id<BugsnagPerformanceSpanControl> result = [self.plugin getSpanControlsWithQuery:query];
    
    XCTAssertNil(result);
}

- (void)testGetSpanControlsWithNonExistentSpanName {
    [self.plugin installWithContext:self.mockContext];
    
    BugsnagPerformanceSpan *span = createSpan(@"my-span");
    FakePluginContext *fakeContext = (FakePluginContext *)self.mockContext;
    
    fakeContext.spanStartCallback(span);
    
    BugsnagPerformanceNamedSpanQuery *query = [BugsnagPerformanceNamedSpanQuery queryWithName:@"non-existent"];
    id<BugsnagPerformanceSpanControl> result = [self.plugin getSpanControlsWithQuery:query];
    
    XCTAssertNil(result);
}

- (void)testGetSpanControlsWithEmptyCache {
    [self.plugin installWithContext:self.mockContext];
    
    BugsnagPerformanceNamedSpanQuery *query = [BugsnagPerformanceNamedSpanQuery queryWithName:@"any-span"];
    id<BugsnagPerformanceSpanControl> result = [self.plugin getSpanControlsWithQuery:query];
    
    XCTAssertNil(result);
}

#pragma mark - Timeout Tests

- (void)testSpanTimeoutTimerRemovesSpanFromCache {
    [self.plugin installWithContext:self.mockContext];
    
    BugsnagPerformanceSpan *span = createSpan(@"timeout-span");
    FakePluginContext *fakeContext = (FakePluginContext *)self.mockContext;
    
    // Start span (creates timeout timer)
    fakeContext.spanStartCallback(span);
    
    // Verify span is cached
    BugsnagPerformanceNamedSpanQuery *query = [BugsnagPerformanceNamedSpanQuery queryWithName:@"timeout-span"];
    id<BugsnagPerformanceSpanControl> cachedSpan = [self.plugin getSpanControlsWithQuery:query];
    XCTAssertIdentical(cachedSpan, span);

    // Wait for timeout to trigger
    XCTestExpectation *timeoutExpectation = [self expectationWithDescription:@"Span timeout should remove span from cache"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Check span is removed from cache after timeout interval
        id<BugsnagPerformanceSpanControl> stillCachedSpan = [self.plugin getSpanControlsWithQuery:query];
        XCTAssertNil(stillCachedSpan);
        [timeoutExpectation fulfill];
    });
    
    [self waitForExpectations:@[timeoutExpectation] timeout:0.5];
}


- (void)testTimeoutIsRenewedWhenNewSpanWithSameNameStarted {
    [self.plugin installWithContext:self.mockContext];
    
    BugsnagPerformanceSpan *span1 = createSpan(@"test-span");
    BugsnagPerformanceSpan *span2 = createSpan(@"test-span");
    FakePluginContext *fakeContext = (FakePluginContext *)self.mockContext;
    
    // Start first span (creates timeout timer)
    fakeContext.spanStartCallback(span1);
    
    // Verify first span is cached
    BugsnagPerformanceNamedSpanQuery *query = [BugsnagPerformanceNamedSpanQuery queryWithName:@"test-span"];
    id<BugsnagPerformanceSpanControl> cachedSpan = [self.plugin getSpanControlsWithQuery:query];
    XCTAssertIdentical(cachedSpan, span1);

    // Wait for first span's timeout to almost elapse (0.15 seconds of 0.2 second timeout)
    XCTestExpectation *stagingExpectation = [self expectationWithDescription:@"Second span with same name should replace first span"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        // Start second span with same name (should cancel first timer and create a new one)
        fakeContext.spanStartCallback(span2);
        
        // Verify second span replaced first span
        id<BugsnagPerformanceSpanControl> newCachedSpan = [self.plugin getSpanControlsWithQuery:query];
        XCTAssertIdentical(newCachedSpan, span2);

        [stagingExpectation fulfill];
    });
    
    [self waitForExpectations:@[stagingExpectation] timeout:0.3];
    
    // Now wait for the original first span's timeout period to fully elapse (0.1 more seconds)
    XCTestExpectation *timeoutExpectation = [self expectationWithDescription:@"Second span with same name should create a new timeout"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Verify second span is still cached
        id<BugsnagPerformanceSpanControl> stillCachedSpan = [self.plugin getSpanControlsWithQuery:query];
        XCTAssertIdentical(stillCachedSpan, span2);
        [timeoutExpectation fulfill];
    });
    
    [self waitForExpectations:@[timeoutExpectation] timeout:0.3];
}

- (void)testMultipleSpansWithDifferentNamesAreRemovedFromCacheOnTheirTimeout {
    [self.plugin installWithContext:self.mockContext];
    
    BugsnagPerformanceSpan *span1 = createSpan(@"span-one");
    BugsnagPerformanceSpan *span2 = createSpan(@"span-two");
    BugsnagPerformanceSpan *span3 = createSpan(@"span-three");
    FakePluginContext *fakeContext = (FakePluginContext *)self.mockContext;
    
    // Start first span
    fakeContext.spanStartCallback(span1);

    // Start second span with different name
    fakeContext.spanStartCallback(span2);

    // Start third span with different name
    fakeContext.spanStartCallback(span3);

    // Verify all spans are cached
    BugsnagPerformanceNamedSpanQuery *query1 = [BugsnagPerformanceNamedSpanQuery queryWithName:@"span-one"];
    BugsnagPerformanceNamedSpanQuery *query2 = [BugsnagPerformanceNamedSpanQuery queryWithName:@"span-two"];
    BugsnagPerformanceNamedSpanQuery *query3 = [BugsnagPerformanceNamedSpanQuery queryWithName:@"span-three"];
    
    XCTAssertIdentical([self.plugin getSpanControlsWithQuery:query1], span1);
    XCTAssertIdentical([self.plugin getSpanControlsWithQuery:query2], span2);
    XCTAssertIdentical([self.plugin getSpanControlsWithQuery:query3], span3);
    
    // End middle span - should only remove its timer
    BOOL result = fakeContext.spanEndCallback(span2);
    XCTAssertTrue(result);

    // Verify span2 is removed but span1 and span3 remain
    XCTAssertIdentical([self.plugin getSpanControlsWithQuery:query1], span1);
    XCTAssertNil([self.plugin getSpanControlsWithQuery:query2]);
    XCTAssertIdentical([self.plugin getSpanControlsWithQuery:query3], span3);
    
    // Wait for timeout to trigger on remaining spans
    XCTestExpectation *timeoutExpectation = [self expectationWithDescription:@"Remaining spans should timeout"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Both remaining spans should be removed by timeout
        XCTAssertNil([self.plugin getSpanControlsWithQuery:query1]);
        XCTAssertNil([self.plugin getSpanControlsWithQuery:query3]);
        [timeoutExpectation fulfill];
    });
    
    [self waitForExpectations:@[timeoutExpectation] timeout:0.5];
}

#pragma mark - Thread Safety Tests

- (void)testConcurrentSpanOperations {
    [self.plugin installWithContext:self.mockContext];
    
    FakePluginContext *fakeContext = (FakePluginContext *)self.mockContext;
    
    // Create multiple spans concurrently
    dispatch_group_t group = dispatch_group_create();
    for (int i = 0; i < 10; i++) {
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BugsnagPerformanceSpan *span = createSpan([NSString stringWithFormat:@"span-%d", i]);
            fakeContext.spanStartCallback(span);
        });
    }
    
    // Wait for all spans to be created
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    // Verify all spans are cached
    NSMutableArray *spans = [NSMutableArray new];
    for (int i = 0; i < 10; i++) {
        BugsnagPerformanceNamedSpanQuery *query = [BugsnagPerformanceNamedSpanQuery queryWithName:[NSString stringWithFormat:@"span-%d", i]];
        id<BugsnagPerformanceSpanControl> result = [self.plugin getSpanControlsWithQuery:query];
        XCTAssertNotNil(result);
        [spans addObject:result];
    }
    
    // End all spans concurrently
    for (BugsnagPerformanceSpan *span in spans) {
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            fakeContext.spanEndCallback(span);
        });
    }
    
    // Wait for all spans to be ended
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    // Verify all spans are removed from cache
    for (int i = 0; i < 10; i++) {
        BugsnagPerformanceNamedSpanQuery *query = [BugsnagPerformanceNamedSpanQuery queryWithName:[NSString stringWithFormat:@"span-%d", i]];
        id<BugsnagPerformanceSpanControl> result = [self.plugin getSpanControlsWithQuery:query];
        XCTAssertNil(result);
    }
}

@end
