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
    BugsnagPerformanceLibrary::testing_reset();
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"];
    config.autoInstrumentViewControllers = NO;
    config.autoInstrumentAppStarts = NO;
    config.autoInstrumentNetworkRequests = NO;
    BugsnagPerformanceLibrary::configureLibrary(config);
    BugsnagPerformanceLibrary::startLibrary();
    auto perf = BugsnagPerformanceLibrary::getBugsnagPerformanceImpl();
    @autoreleasepool {
        UIViewController *controller = [UIViewController new];
        perf->startViewLoadSpan(controller, [BugsnagPerformanceSpanOptions new]);
        XCTAssertEqual(1U, perf->testing_getViewControllersToSpansCount());
        perf->endViewLoadSpan(controller, [NSDate date]);
        XCTAssertEqual(0U, perf->testing_getViewControllersToSpansCount());
    }
}

- (void)testForgotToEnd {
    BugsnagPerformanceLibrary::testing_reset();
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"];
    config.autoInstrumentViewControllers = NO;
    config.autoInstrumentAppStarts = NO;
    config.autoInstrumentNetworkRequests = NO;
    BugsnagPerformanceLibrary::configureLibrary(config);
    BugsnagPerformanceLibrary::startLibrary();
    auto perf = BugsnagPerformanceLibrary::getBugsnagPerformanceImpl();
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

- (void)testAutoViewControllerDidAppearWillDisappear {
    // Combined into one test because there is some memory corruption bug when
    // testing_reset() is called multiple times.
    BugsnagPerformanceLibrary::testing_reset();
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"];
    config.autoInstrumentViewControllers = YES;
    config.autoInstrumentAppStarts = NO;
    config.autoInstrumentNetworkRequests = NO;
    BugsnagPerformanceLibrary::configureLibrary(config);
    BugsnagPerformanceLibrary::startLibrary();
    auto perf = BugsnagPerformanceLibrary::getBugsnagPerformanceImpl();
    perf->testing_setProbability(1);
    XCTAssertEqual(0U, perf->testing_getBatchCount());
    UIViewController *controller = [MyTestViewController new];
    [controller loadView];
    [controller viewDidLoad];
    XCTAssertEqual(0U, perf->testing_getBatchCount());
    [controller viewDidAppear:controller];
    XCTAssertEqual(1U, perf->testing_getBatchCount());

    controller = [MyTestViewController new];
    [controller loadView];
    [controller viewDidLoad];
    XCTAssertEqual(1U, perf->testing_getBatchCount());
// Temporarily disabled to stop crashes while we build a more complete solution
//    [controller viewWillDisappear:controller];
//    XCTAssertEqual(2U, perf->testing_getBatchCount());
}

@end
