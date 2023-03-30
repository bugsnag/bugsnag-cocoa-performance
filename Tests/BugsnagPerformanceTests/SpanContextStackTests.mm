//
//  SpanContextStackTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 17.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SpanContextStack+Private.h"
#import "BugsnagPerformanceSpan+Private.h"

#import <objc/runtime.h>
#import <os/activity.h>
#import <mutex>

using namespace bugsnag;

@interface SpanContextStackTests : XCTestCase

@end

@implementation SpanContextStackTests

// To make sure these tests will never run in parallel.
[[clang::no_destroy]] static std::mutex mutex;

// To make sure all threads exit before continuing.
static std::atomic<int> counter;

static BugsnagPerformanceSpan *newSpan() {
    TraceId tid = {.value = 1};
    auto data = std::make_unique<SpanData>(@"test", tid, 1, 0, 0, BSGFirstClassUnset);
    auto span = std::make_unique<Span>(std::move(data), ^(std::shared_ptr<SpanData>) {});
    return [[BugsnagPerformanceSpan alloc] initWithSpan:std::move(span)];
}

/* Implementation Note:
 * The ordering of the first two tests must not be changed because they require specific
 * starting states and there's no way to reset activity tracing between tests.
 *
 * - test0001EmptyStack relies upon activity tracing being uninitialized.
 * - test0002Stress relies upon there being no running activities.
 * - The other tests must work regardless of existing state.
 *
 * Test run order is alphabetical.
 */

- (void)test0001EmptyStack {
    std::lock_guard<std::mutex> guard(mutex);
    [SpanContextStack.current clearForUnitTests];

    XCTAssertNotNil(SpanContextStack.current);
    XCTAssertNil(SpanContextStack.current.context);
}

- (void)test0002QueueStress {
    std::lock_guard<std::mutex> guard(mutex);
    [SpanContextStack.current clearForUnitTests];

    // Test that multiple dispatch queues using the same stack from different threads doesn't break.
    static const int iteration_count = 10000;
    static const int queue_count = 10;
    dispatch_queue_t queues[queue_count];

    for (int i = 0; i < queue_count; i++) {
        NSString *name = [NSString stringWithFormat:@"test-%d", i];
        queues[i] = dispatch_queue_create(name.UTF8String, DISPATCH_QUEUE_CONCURRENT);
    }

    counter = 0;
    for (int i = 0; i < queue_count; i++) {
        dispatch_async(queues[i], ^{
            counter++;
            for (int j = 0; j < iteration_count; j++) {
                auto span1 = newSpan();
                [SpanContextStack.current push:span1];
                [span1 end];
                [SpanContextStack.current context];
            }
            counter--;
        });
    }

    usleep(200000);
    while(counter > 0) {
        usleep(100000);
    }
    XCTAssertLessThan(SpanContextStack.current.stacks.count, 100000UL);
}

- (void)test0003ThreadStress {
    std::lock_guard<std::mutex> guard(mutex);
    [SpanContextStack.current clearForUnitTests];

    // Test that multiple dispatch queues using the same stack from different threads doesn't break.
    static const int iteration_count = 10000;
    static const int queue_count = 10;
    dispatch_queue_t queues[queue_count];

    const auto beginCount = SpanContextStack.current.stacks.count;

    for (int i = 0; i < queue_count; i++) {
        NSString *name = [NSString stringWithFormat:@"test-%d", i];
        queues[i] = dispatch_queue_create(name.UTF8String, DISPATCH_QUEUE_CONCURRENT);
    }

    counter = 0;
    for (int i = 0; i < queue_count; i++) {
        [NSThread detachNewThreadWithBlock:^{
            counter++;
            for (int j = 0; j < iteration_count; j++) {
                auto span1 = newSpan();
                [SpanContextStack.current push:span1];
                [span1 end];
                [SpanContextStack.current context];
            }
            counter--;
        }];
    }

    usleep(200000);
    while(counter > 0) {
        usleep(100000);
    }
    XCTAssertEqual(SpanContextStack.current.stacks.count, beginCount);
}

- (void)testCurrent {
    std::lock_guard<std::mutex> guard(mutex);
    [SpanContextStack.current clearForUnitTests];

    XCTAssertNotNil(SpanContextStack.current);
    auto span = newSpan();
    [SpanContextStack.current push:span];
    XCTAssertEqual(span, SpanContextStack.current.context);
}

- (void)testOneEntryEnded {
    std::lock_guard<std::mutex> guard(mutex);
    [SpanContextStack.current clearForUnitTests];

    XCTAssertNotNil(SpanContextStack.current);
    auto span = newSpan();
    [SpanContextStack.current push:span];
    [span end];
    XCTAssertNil(SpanContextStack.current.context);
}

- (void)testCurrentEnded {
    std::lock_guard<std::mutex> guard(mutex);
    [SpanContextStack.current clearForUnitTests];

    XCTAssertNotNil(SpanContextStack.current);
    auto span1 = newSpan();
    auto span2 = newSpan();
    [SpanContextStack.current push:span1];
    XCTAssertEqual(span1, SpanContextStack.current.context);
    [SpanContextStack.current push:span2];
    XCTAssertEqual(span2, SpanContextStack.current.context);
    [span2 end];
    XCTAssertNotNil(SpanContextStack.current.context);
    XCTAssertEqual(span1, SpanContextStack.current.context);
    [span1 end];
    XCTAssertNil(SpanContextStack.current.context);
}

- (void)testMiddleEnded {
    std::lock_guard<std::mutex> guard(mutex);
    [SpanContextStack.current clearForUnitTests];

    XCTAssertNotNil(SpanContextStack.current);
    auto span1 = newSpan();
    auto span2 = newSpan();
    auto span3 = newSpan();
    [SpanContextStack.current push:span1];
    [SpanContextStack.current push:span2];
    [SpanContextStack.current push:span3];
    XCTAssertEqual(span3, SpanContextStack.current.context);
    [span2 end];
    XCTAssertEqual(span3, SpanContextStack.current.context);
    [span3 end];
    XCTAssertEqual(span1, SpanContextStack.current.context);
    [span1 end];
    XCTAssertNil(SpanContextStack.current.context);
}

- (void)testMultithreaded {
    std::lock_guard<std::mutex> guard(mutex);
    [SpanContextStack.current clearForUnitTests];

    counter = 1;
    // A different thread's span context stack should be separate.
    [NSThread detachNewThreadWithBlock:^{
        usleep(100000);
        XCTAssertNotNil(SpanContextStack.current);
        auto span1 = newSpan();
        auto span2 = newSpan();
        auto span3 = newSpan();
        [SpanContextStack.current push:span1];
        usleep(100000);
        [SpanContextStack.current push:span2];
        usleep(100000);
        [SpanContextStack.current push:span3];
        XCTAssertEqual(span3, SpanContextStack.current.context);
        counter--;
    }];
    
    XCTAssertNotNil(SpanContextStack.current);
    auto span1 = newSpan();
    auto span2 = newSpan();
    auto span3 = newSpan();
    [SpanContextStack.current push:span1];
    [SpanContextStack.current push:span2];
    [SpanContextStack.current push:span3];

    while(counter > 0) {
        usleep(100000);
    }
    XCTAssertEqual(span3, SpanContextStack.current.context);
}

- (void)testDispatchQueue {
    std::lock_guard<std::mutex> guard(mutex);
    [SpanContextStack.current clearForUnitTests];

    // Span context stacks must traverse dispatch queue boundaries
    XCTAssertNotNil(SpanContextStack.current);
    auto span1 = newSpan();
    [SpanContextStack.current push:span1];

    counter = 1;
    __block auto span2 = newSpan();
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [SpanContextStack.current push:span2];
        counter--;
    });

    while(counter > 0) {
        usleep(100000);
    }
    XCTAssertEqual(span2, SpanContextStack.current.context);
}

- (void)testFindAttribute {
    std::lock_guard<std::mutex> guard(mutex);
    [SpanContextStack.current clearForUnitTests];

    auto span_a = newSpan();
    [span_a addAttributes:@{
        @"a": @"1"
    }];
    [SpanContextStack.current push:span_a];
    
    XCTAssertTrue([SpanContextStack.current hasSpanWithAttribute:@"a" value:@"1"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"a" value:@"2"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"z" value:@"1"]);
    
    auto span_b = newSpan();
    [span_b addAttributes:@{
        @"b": @"2"
    }];
    [SpanContextStack.current push:span_b];
    XCTAssertTrue([SpanContextStack.current hasSpanWithAttribute:@"a" value:@"1"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"a" value:@"2"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"z" value:@"1"]);
    XCTAssertTrue([SpanContextStack.current hasSpanWithAttribute:@"b" value:@"2"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"b" value:@"1"]);
    
    auto span_c = newSpan();
    [span_c addAttributes:@{
        @"c": @"2",
        @"d": @"100",
    }];
    [SpanContextStack.current push:span_c];
    XCTAssertTrue([SpanContextStack.current hasSpanWithAttribute:@"a" value:@"1"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"a" value:@"2"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"z" value:@"1"]);
    XCTAssertTrue([SpanContextStack.current hasSpanWithAttribute:@"b" value:@"2"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"b" value:@"1"]);
    XCTAssertTrue([SpanContextStack.current hasSpanWithAttribute:@"c" value:@"2"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"c" value:@"1"]);
    XCTAssertTrue([SpanContextStack.current hasSpanWithAttribute:@"d" value:@"100"]);
    
    [span_a end];
    [SpanContextStack current]; // Force a sweep
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"a" value:@"1"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"a" value:@"2"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"z" value:@"1"]);
    XCTAssertTrue([SpanContextStack.current hasSpanWithAttribute:@"b" value:@"2"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"b" value:@"1"]);
    XCTAssertTrue([SpanContextStack.current hasSpanWithAttribute:@"c" value:@"2"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"c" value:@"1"]);
    XCTAssertTrue([SpanContextStack.current hasSpanWithAttribute:@"d" value:@"100"]);
    
    [span_c end];
    [SpanContextStack current]; // Force a sweep
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"a" value:@"1"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"a" value:@"2"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"z" value:@"1"]);
    XCTAssertTrue([SpanContextStack.current hasSpanWithAttribute:@"b" value:@"2"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"b" value:@"1"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"c" value:@"2"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"c" value:@"1"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"d" value:@"100"]);
    
    [span_b end];
    [SpanContextStack current]; // Force a sweep
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"a" value:@"1"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"a" value:@"2"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"z" value:@"1"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"b" value:@"2"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"b" value:@"1"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"c" value:@"2"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"c" value:@"1"]);
    XCTAssertFalse([SpanContextStack.current hasSpanWithAttribute:@"d" value:@"100"]);
}

@end
