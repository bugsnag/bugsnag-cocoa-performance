//
//  TimeTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 16.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Utils.h"

using namespace bugsnag;

@interface TimeTests : XCTestCase

@end

@implementation TimeTests

- (void)testTimeToNanoseconds {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    dispatch_time_t time = absoluteTimeToNanoseconds(dateToAbsoluteTime(date));
    
    XCTAssertEqual(0U, time);
    
    date = [NSDate dateWithTimeIntervalSince1970:1000];
    time = absoluteTimeToNanoseconds(dateToAbsoluteTime(date));
    
    XCTAssertEqual(1000000000000ULL, time);
}

- (void)testCurrentTime {
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime dateToTime = dateToAbsoluteTime([NSDate date]);
    
    XCTAssertTrue(abs(now - dateToTime) < 0.1);
}

@end
