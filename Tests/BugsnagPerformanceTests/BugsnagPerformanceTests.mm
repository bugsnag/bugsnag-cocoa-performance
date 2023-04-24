//
//  BugsnagPerformanceTests.m
//  BugsnagPerformance
//
//  Created by Nick Dowell on 26/09/2022.
//

#import <XCTest/XCTest.h>

#import <BugsnagPerformance/BugsnagPerformance.h>

@interface BugsnagPerformanceTests : XCTestCase

@end

@implementation BugsnagPerformanceTests

- (void)setUp {
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"0123456789abcdef0123456789abcdef"];
    config.endpoint = [NSURL URLWithString:@"http://localhost"];
    config.autoInstrumentNetworkRequests = NO;
    config.autoInstrumentAppStarts = NO;
    config.autoInstrumentViewControllers = NO;
    [BugsnagPerformance startWithConfiguration:config];
}

- (void)testStartSpanWithName {
    auto span = [BugsnagPerformance startSpanWithName:@"Test"];
    XCTAssertNotNil(span);
    [span end];
}

@end
