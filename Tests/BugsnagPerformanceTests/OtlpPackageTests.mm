//
//  OtlpPackageTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 18.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OtlpPackage.h"

using namespace bugsnag;

@interface OtlpPackageTests : XCTestCase

@end

@implementation OtlpPackageTests

- (void)testEncoding {
    NSDictionary *headers = @{
        @"a": @"b",
        @"c": @"d",
    };
    NSData *payload = [@"blah" dataUsingEncoding:NSUTF8StringEncoding];
    dispatch_time_t ts = 1000;

    OtlpPackage package(ts, payload, headers);
    XCTAssertTrue(package == package);

    NSData *serialized = package.serialize();
    XCTAssertEqualObjects(@"a: b\r\nc: d\r\nBugsnag-Integrity: sha1 5bf1fd927dfb8679496a2e6cf00cbe50c1c87145\r\n\r\nblah",
                          [[NSString alloc] initWithData:serialized encoding:NSUTF8StringEncoding]);

    auto deserialized = deserializeOtlpPackage(ts, serialized);
    XCTAssertTrue(package == *deserialized);
}

- (void)testOperatorEquals {
    OtlpPackage baseline(1, [@"a" dataUsingEncoding:NSUTF8StringEncoding], @{@"a": @"b"});
    XCTAssertTrue(baseline == baseline);
    XCTAssertTrue(baseline == OtlpPackage(1, [@"a" dataUsingEncoding:NSUTF8StringEncoding], @{@"a": @"b"}));
    XCTAssertFalse(baseline == OtlpPackage(2, [@"a" dataUsingEncoding:NSUTF8StringEncoding], @{@"a": @"b"}));
    XCTAssertFalse(baseline == OtlpPackage(1, [@"b" dataUsingEncoding:NSUTF8StringEncoding], @{@"a": @"b"}));
    XCTAssertFalse(baseline == OtlpPackage(1, [@"a" dataUsingEncoding:NSUTF8StringEncoding], @{@"b": @"b"}));
}

- (void)testCorruptedData {
    NSData *payload = [@"blah" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertEqual(nullptr, deserializeOtlpPackage(1000, payload));
}

@end
