//
//  SetupPerformanceTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Robert B on 16/08/2023.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "BugsnagPerformanceLibrary.h"
#import "BugsnagPerformanceImpl.h"

using namespace bugsnag;

@interface SetupPerformanceTests : XCTestCase

@end

@implementation SetupPerformanceTests

- (void)testBugsnagEarlySetupTime API_AVAILABLE(ios(13)) {
    if ([self respondsToSelector:@selector(measureWithOptions:block:)]) {
        XCTMeasureOptions *options = [XCTMeasureOptions defaultOptions];
        options.iterationCount = 100;
        [self measureWithOptions:options block:^{
            auto performance = std::make_shared<BugsnagPerformanceImpl>(BugsnagPerformanceLibrary::getReachability(), BugsnagPerformanceLibrary::getAppStateTracker());
            performance->earlySetup();
        }];
    }
}

@end
