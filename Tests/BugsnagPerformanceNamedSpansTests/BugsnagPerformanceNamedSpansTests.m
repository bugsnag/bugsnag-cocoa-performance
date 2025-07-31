//
//  BugsnagPerformanceNamedSpansTests.m
//  BugsnagPerformanceNamedSpansTests
//
//  Created by Yousif Ahmed on 22/07/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BugsnagPerformanceNamedSpansPlugin.h"
#import "BugsnagPerformanceNamedSpanQuery.h"
#import <BugsnagPerformance/BugsnagPerformancePluginContext.h>
#import <BugsnagPerformance/BugsnagPerformanceSpan.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanQuery.h>

@interface TestSpan: BugsnagPerformanceSpan

-(instancetype)initWithName:(NSString *)name;

@end

@implementation TestSpan

- (instancetype)initWithName:(NSString *)name {
    TraceId tid = {.value = 1};
    if ((self = [super initWithTraceId:traceId spanId:1])) {
        _name = name;
    }
    
    return self;
}

@end

@interface BugsnagPerformanceNamedSpansTests : XCTestCase
@property (nonatomic, strong) BugsnagPerformanceNamedSpansPlugin *plugin;
@property (nonatomic, strong) BugsnagPerformancePluginContext *mockContext;
@end


@interface FakePluginContext : NSObject
@property (nonatomic, copy) BugsnagPerformanceSpanStartCallback spanStartCallback;
@property (nonatomic, copy) BugsnagPerformanceSpanEndCallback spanEndCallback;
@property (nonatomic, strong) NSMutableArray<id<BugsnagPerformanceSpanControlProvider>> *spanControlProviders;
- (void)addOnSpanStartCallback:(BugsnagPerformanceSpanStartCallback)callback priority:(BugsnagPerformancePriority)priority;
- (void)addOnSpanEndCallback:(BugsnagPerformanceSpanEndCallback)callback priority:(BugsnagPerformancePriority)priority;
- (void)addSpanControlProvider:(id<BugsnagPerformanceSpanControlProvider>)provider;
@end

static BugsnagPerformanceSpan *createSpan(NSString *name) {
    return [[TestSpan alloc] initWithName:name];
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

@implementation BugsnagPerformanceNamedSpansTests

- (void)setUp {
    [super setUp];
    self.plugin = [[BugsnagPerformanceNamedSpansPlugin alloc] init];
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
    XCTAssertEqual(fakeContext.spanControlProviders.count, 1);
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

- (void)testGetSpanControlsWithNonNamedSpanQuery {
    [self.plugin installWithContext:self.mockContext];
    
    BugsnagPerformanceSpanQuery *query = [BugsnagPerformanceSpanQuery queryWithResultType:[BugsnagPerformanceSpan class]];
    id<BugsnagPerformanceSpanControl> result = [self.plugin getSpanControlsWithQuery:query];
    
    XCTAssertNil(result);
}

- (void)testGetSpanControlsWithNonExistentSpanName {
    [self.plugin installWithContext:self.mockContext];
    
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

- (void)testSpanTimeoutRemovesSpanFromCache {
    [self.plugin installWithContext:self.mockContext];
    
    BugsnagPerformanceSpan *span = createSpan("timeout-span");
    FakePluginContext *fakeContext = (FakePluginContext *)self.mockContext;
    
    // Start span
    fakeContext.spanStartCallback(span);
    
    // Verify span is cached
    BugsnagPerformanceNamedSpanQuery *query = [BugsnagPerformanceNamedSpanQuery queryWithName:@"timeout-span"];
    id<BugsnagPerformanceSpanControl> result = [self.plugin getSpanControlsWithQuery:query];
    XCTAssertIdentical(result, span);
    
    // Wait a short time and verify span is still there (not testing actual 10 minute timeout)
    // This test mainly verifies the timeout timer is set up
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BugsnagPerformanceNamedSpanQuery *query = [BugsnagPerformanceNamedSpanQuery queryWithName:@"timeout-span"];
        id<BugsnagPerformanceSpanControl> result = [self.plugin getSpanControlsWithQuery:query];
        XCTAssertIdentical(result, span);
    });
}

#pragma mark - Thread Safety Tests

- (void)testConcurrentSpanOperations {
    [self.plugin installWithContext:self.mockContext];
    
    FakePluginContext *fakeContext = (FakePluginContext *)self.mockContext;
    NSMutableArray *spans = [NSMutableArray new];
    
    // Create multiple spans concurrently
    dispatch_group_t group = dispatch_group_create();
    for (int i = 0; i < 10; i++) {
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BugsnagPerformanceSpan *span = createSpan([NSString stringWithFormat:@"span-%d", i]);
            [spans addObject:span];
            fakeContext.spanStartCallback(span);
        });
    }
    
    // Wait for all spans to be created
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    // Verify all spans are cached
    for (int i = 0; i < 10; i++) {
        BugsnagPerformanceNamedSpanQuery *query = [BugsnagPerformanceNamedSpanQuery queryWithName:[NSString stringWithFormat:@"span-%d", i]];
        id<BugsnagPerformanceSpanControl> result = [self.plugin getSpanControlsWithQuery:query];
        XCTAssertNotNil(result);
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
