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
    auto span = std::make_unique<Span>(@"test", tid, 1, 0, 0, BSGFirstClassUnset, ^(std::shared_ptr<SpanData>) {});
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
    auto spanContextStack = [SpanContextStack new];

    XCTAssertNotNil(spanContextStack);
    XCTAssertNil(spanContextStack.context);
}

- (void)test0002QueueStress {
    std::lock_guard<std::mutex> guard(mutex);
    auto spanContextStack = [SpanContextStack new];

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
                [spanContextStack push:span1];
                [span1 end];
                [spanContextStack context];
            }
            counter--;
        });
    }

    usleep(200000);
    while(counter > 0) {
        usleep(100000);
    }
    XCTAssertLessThan(spanContextStack.stacks.count, 100000UL);
}

- (void)test0003ThreadStress {
    std::lock_guard<std::mutex> guard(mutex);
    auto spanContextStack = [SpanContextStack new];

    // Test that multiple dispatch queues using the same stack from different threads doesn't break.
    static const int iteration_count = 10000;
    static const int queue_count = 10;
    dispatch_queue_t queues[queue_count];

    const auto beginCount = spanContextStack.stacks.count;

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
                [spanContextStack push:span1];
                [span1 end];
                [spanContextStack context];
            }
            counter--;
        }];
    }

    usleep(200000);
    while(counter > 0) {
        usleep(100000);
    }
    XCTAssertEqual(spanContextStack.stacks.count, beginCount);
}

- (void)testCurrent {
    std::lock_guard<std::mutex> guard(mutex);
    auto spanContextStack = [SpanContextStack new];

    XCTAssertNotNil(spanContextStack);
    auto span = newSpan();
    [spanContextStack push:span];
    XCTAssertEqual(span, spanContextStack.context);
}

- (void)testOneEntryEnded {
    std::lock_guard<std::mutex> guard(mutex);
    auto spanContextStack = [SpanContextStack new];

    XCTAssertNotNil(spanContextStack);
    auto span = newSpan();
    [spanContextStack push:span];
    [span end];
    XCTAssertNil(spanContextStack.context);
}

- (void)testCurrentEnded {
    std::lock_guard<std::mutex> guard(mutex);
    auto spanContextStack = [SpanContextStack new];

    XCTAssertNotNil(spanContextStack);
    auto span1 = newSpan();
    auto span2 = newSpan();
    [spanContextStack push:span1];
    XCTAssertEqual(span1, spanContextStack.context);
    [spanContextStack push:span2];
    XCTAssertEqual(span2, spanContextStack.context);
    [span2 end];
    XCTAssertNotNil(spanContextStack.context);
    XCTAssertEqual(span1, spanContextStack.context);
    [span1 end];
    XCTAssertNil(spanContextStack.context);
}

- (void)testMiddleEnded {
    std::lock_guard<std::mutex> guard(mutex);
    auto spanContextStack = [SpanContextStack new];

    XCTAssertNotNil(spanContextStack);
    auto span1 = newSpan();
    auto span2 = newSpan();
    auto span3 = newSpan();
    [spanContextStack push:span1];
    [spanContextStack push:span2];
    [spanContextStack push:span3];
    XCTAssertEqual(span3, spanContextStack.context);
    [span2 end];
    XCTAssertEqual(span3, spanContextStack.context);
    [span3 end];
    XCTAssertEqual(span1, spanContextStack.context);
    [span1 end];
    XCTAssertNil(spanContextStack.context);
}

- (void)testMultithreaded {
    std::lock_guard<std::mutex> guard(mutex);
    auto spanContextStack = [SpanContextStack new];

    counter = 1;
    // A different thread's span context stack should be separate.
    [NSThread detachNewThreadWithBlock:^{
        usleep(100000);
        XCTAssertNotNil(spanContextStack);
        auto span1 = newSpan();
        auto span2 = newSpan();
        auto span3 = newSpan();
        [spanContextStack push:span1];
        usleep(100000);
        [spanContextStack push:span2];
        usleep(100000);
        [spanContextStack push:span3];
        XCTAssertEqual(span3, spanContextStack.context);
        counter--;
    }];
    
    XCTAssertNotNil(spanContextStack);
    auto span1 = newSpan();
    auto span2 = newSpan();
    auto span3 = newSpan();
    [spanContextStack push:span1];
    [spanContextStack push:span2];
    [spanContextStack push:span3];

    while(counter > 0) {
        usleep(100000);
    }
    XCTAssertEqual(span3, spanContextStack.context);
}

- (void)testDispatchQueue {
    std::lock_guard<std::mutex> guard(mutex);
    auto spanContextStack = [SpanContextStack new];

    // Span context stacks must traverse dispatch queue boundaries
    XCTAssertNotNil(spanContextStack);
    auto span1 = newSpan();
    [spanContextStack push:span1];

    counter = 1;
    __block auto span2 = newSpan();
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [spanContextStack push:span2];
        counter--;
    });

    while(counter > 0) {
        usleep(100000);
    }
    XCTAssertEqual(span2, spanContextStack.context);
}

- (void)testFindAttribute {
    std::lock_guard<std::mutex> guard(mutex);
    auto spanContextStack = [SpanContextStack new];

    auto span_a = newSpan();
    [span_a addAttributes:@{
        @"a": @"1"
    }];
    [spanContextStack push:span_a];
    
    XCTAssertTrue([spanContextStack hasSpanWithAttribute:@"a" value:@"1"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"a" value:@"2"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"z" value:@"1"]);
    
    auto span_b = newSpan();
    [span_b addAttributes:@{
        @"b": @"2"
    }];
    [spanContextStack push:span_b];
    XCTAssertTrue([spanContextStack hasSpanWithAttribute:@"a" value:@"1"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"a" value:@"2"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"z" value:@"1"]);
    XCTAssertTrue([spanContextStack hasSpanWithAttribute:@"b" value:@"2"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"b" value:@"1"]);
    
    auto span_c = newSpan();
    [span_c addAttributes:@{
        @"c": @"2",
        @"d": @"100",
    }];
    [spanContextStack push:span_c];
    XCTAssertTrue([spanContextStack hasSpanWithAttribute:@"a" value:@"1"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"a" value:@"2"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"z" value:@"1"]);
    XCTAssertTrue([spanContextStack hasSpanWithAttribute:@"b" value:@"2"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"b" value:@"1"]);
    XCTAssertTrue([spanContextStack hasSpanWithAttribute:@"c" value:@"2"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"c" value:@"1"]);
    XCTAssertTrue([spanContextStack hasSpanWithAttribute:@"d" value:@"100"]);
    
    [span_a end];
    [spanContextStack context]; // Force a sweep
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"a" value:@"1"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"a" value:@"2"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"z" value:@"1"]);
    XCTAssertTrue([spanContextStack hasSpanWithAttribute:@"b" value:@"2"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"b" value:@"1"]);
    XCTAssertTrue([spanContextStack hasSpanWithAttribute:@"c" value:@"2"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"c" value:@"1"]);
    XCTAssertTrue([spanContextStack hasSpanWithAttribute:@"d" value:@"100"]);
    
    [span_c end];
    [spanContextStack context]; // Force a sweep
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"a" value:@"1"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"a" value:@"2"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"z" value:@"1"]);
    XCTAssertTrue([spanContextStack hasSpanWithAttribute:@"b" value:@"2"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"b" value:@"1"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"c" value:@"2"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"c" value:@"1"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"d" value:@"100"]);
    
    [span_b end];
    [spanContextStack context]; // Force a sweep
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"a" value:@"1"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"a" value:@"2"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"z" value:@"1"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"b" value:@"2"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"b" value:@"1"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"c" value:@"2"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"c" value:@"1"]);
    XCTAssertFalse([spanContextStack hasSpanWithAttribute:@"d" value:@"100"]);
}

@end
