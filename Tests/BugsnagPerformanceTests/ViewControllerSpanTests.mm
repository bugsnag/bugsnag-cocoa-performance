//
//  ViewControllerSpanTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 14.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "BugsnagPerformanceImpl.h"
#import "BugsnagPerformanceLibrary.h"

using namespace bugsnag;

@interface MyTestViewController: UIViewController
@end

@implementation MyTestViewController
@end

@interface ViewControllerSpanTests : XCTestCase

@end

@implementation ViewControllerSpanTests

- (void)testNormalUsage {
    auto perf = BugsnagPerformanceImpl::testing_newInstance();
    @autoreleasepool {
        UIViewController *controller = [UIViewController new];
        perf->startViewLoadSpan(controller, [BugsnagPerformanceSpanOptions new]);
        XCTAssertEqual(1U, perf->testing_getViewControllersToSpansCount());
        perf->endViewLoadSpan(controller, [NSDate date]);
        XCTAssertEqual(0U, perf->testing_getViewControllersToSpansCount());
    }
}

- (void)testForgotToEnd {
    auto perf = BugsnagPerformanceImpl::testing_newInstance();

    @autoreleasepool {
        UIViewController *controller = [UIViewController new];
        perf->startViewLoadSpan(controller, [BugsnagPerformanceSpanOptions new]);
        XCTAssertEqual(1U, perf->testing_getViewControllersToSpansCount());
    }

    /* NSMapTable doesn't actually remove values the moment a weak key is deallocated;
     * it does a sweep during certain operations, such as when the map has to resize.
     * http://cocoamine.net/blog/2013/12/13/nsmaptable-and-zeroing-weak-references/
     */
    XCTAssertEqual(1U, perf->testing_getViewControllersToSpansCount());

    // To test removal, we make a bunch more entries to force the map to resize.
    @autoreleasepool {
        for (int i = 0; i < 100; i++) {
            UIViewController *controller = [UIViewController new];
            perf->startViewLoadSpan(controller, [BugsnagPerformanceSpanOptions new]);
        }

        XCTAssertLessThan(perf->testing_getViewControllersToSpansCount(), 100U);
    }
}

- (void)testAutoViewControllerDidAppear {
    BugsnagPerformanceLibrary::testing_reset();
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"];
    config.autoInstrumentViewControllers = YES;
    config.autoInstrumentAppStarts = NO;
    config.autoInstrumentNetwork = NO;
    BugsnagPerformanceLibrary::configure(config);
    auto perf = BugsnagPerformanceLibrary::getBugsnagPerformanceImpl();
    perf->start();
    perf->testing_setProbability(1);
    XCTAssertEqual(0U, perf->testing_getBatchCount());
    UIViewController *controller = [MyTestViewController new];
    [controller loadView];
    [controller viewDidLoad];
    XCTAssertEqual(0U, perf->testing_getBatchCount());
    [controller viewDidAppear:controller];
    XCTAssertEqual(1U, perf->testing_getBatchCount());
}

- (void)testAutoViewControllerWillDisappear {
    BugsnagPerformanceLibrary::testing_reset();
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"];
    config.autoInstrumentViewControllers = YES;
    config.autoInstrumentAppStarts = NO;
    config.autoInstrumentNetwork = NO;
    BugsnagPerformanceLibrary::configure(config);
    auto perf = BugsnagPerformanceLibrary::getBugsnagPerformanceImpl();
    perf->start();
    perf->testing_setProbability(1);
    XCTAssertEqual(0U, perf->testing_getBatchCount());
    UIViewController *controller = [MyTestViewController new];
    [controller loadView];
    [controller viewDidLoad];
    XCTAssertEqual(0U, perf->testing_getBatchCount());
    [controller viewWillDisappear:controller];
    XCTAssertEqual(1U, perf->testing_getBatchCount());
}

@end
