//
//  SpanContextStackTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 17.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SpanContextStack.h"
#import "BugsnagPerformanceSpan+Private.h"

#import <objc/runtime.h>
#import <os/activity.h>

using namespace bugsnag;

@interface SpanContextStackTests : XCTestCase

@end

@implementation SpanContextStackTests

static BugsnagPerformanceSpan *newSpan() {
    TraceId tid = {.value = 1};
    auto data = std::make_unique<SpanData>(@"test", tid, 1, 0, 0, false);
    auto span = std::make_unique<Span>(std::move(data), ^(std::unique_ptr<SpanData>) {});
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
    XCTAssertNotNil(SpanContextStack.current);
    XCTAssertNil(SpanContextStack.current.context);
}

- (void)test0002Stress {
    // Make sure that multiple dispatch queues using the same stack from different threads doesn't break.
    static const int iteration_count = 100000;
    static const int queue_count = 10;
    dispatch_queue_t queues[queue_count];
    
    sleep(1);
    const auto beginCount = SpanContextStack.current.stacks.count;

    for (int i = 0; i < queue_count; i++) {
        NSString *name = [NSString stringWithFormat:@"test-%d", i];
        queues[i] = dispatch_queue_create(name.UTF8String, DISPATCH_QUEUE_CONCURRENT);
    }

    for (int i = 0; i < queue_count; i++) {
        dispatch_async(queues[i], ^{
            for (int j = 0; j < iteration_count; j++) {
                auto span1 = newSpan();
                [SpanContextStack.current push:span1];
                [span1 end];
                [SpanContextStack.current context];
            }
        });
    }

    sleep(5);
    XCTAssertEqual(SpanContextStack.current.stacks.count, beginCount);
}

- (void)testCurrent {
    XCTAssertNotNil(SpanContextStack.current);
    auto span = newSpan();
    [SpanContextStack.current push:span];
    XCTAssertEqual(span, SpanContextStack.current.context);
}

- (void)testOneEntryEnded {
    XCTAssertNotNil(SpanContextStack.current);
    auto span = newSpan();
    [SpanContextStack.current push:span];
    [span end];
    XCTAssertNil(SpanContextStack.current.context);
}

- (void)testCurrentEnded {
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
    }];
    
    XCTAssertNotNil(SpanContextStack.current);
    auto span1 = newSpan();
    auto span2 = newSpan();
    auto span3 = newSpan();
    [SpanContextStack.current push:span1];
    [SpanContextStack.current push:span2];
    [SpanContextStack.current push:span3];

    usleep(400000);
    XCTAssertEqual(span3, SpanContextStack.current.context);
}

- (void)testDispatchQueue {
    // Span context stacks must traverse dispatch queue boundaries
    XCTAssertNotNil(SpanContextStack.current);
    auto span1 = newSpan();
    [SpanContextStack.current push:span1];

    __block auto span2 = newSpan();
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [SpanContextStack.current push:span2];
    });

    usleep(200000);
    XCTAssertEqual(span2, SpanContextStack.current.context);
}

@end
