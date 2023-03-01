//
//  JSONTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 11.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "FileBasedTest.h"

#import "JSON.h"

using namespace bugsnag;

@interface JSONTests : FileBasedTest

@end

@implementation JSONTests

- (void)testData {
    auto expected = @{
        @"a": @(1),
        @"b": @(true),
        @"c": @"string",
        @"d": @(1.5),
        @"e": @{@"a": @"x"},
        @"f": @[@"1", @"2"],
    };
    NSError *error = nil;
    auto data = JSON::dictionaryToData(expected, &error);
    XCTAssertNil(error);
    XCTAssertNotNil(data);
    auto actual = JSON::dataToDictionary(data, &error);
    XCTAssertNil(error);
    XCTAssertNotNil(actual);
    XCTAssertEqualObjects(expected, actual);

    // Make sure NSJSONSerialization agrees
    actual = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(actual);
    XCTAssertEqualObjects(expected, actual);
}

- (void)testFiles {
    auto expected = @{
        @"a": @(1),
        @"b": @(true),
        @"c": @"string",
        @"d": @(1.5),
        @"e": @{@"a": @"x"},
        @"f": @[@"1", @"2"],
    };
    NSError *error = JSON::dictionaryToFile(self.filePath, expected);
    XCTAssertNil(error);
    auto actual = JSON::fileToDictionary(self.filePath, &error);
    XCTAssertNil(error);
    XCTAssertNotNil(actual);
    XCTAssertEqualObjects(expected, actual);
}

@end
