//
//  RetryQueueTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 19.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "FileBasedTest.h"
#import "RetryQueue.h"
#import "BugsnagPerformanceConfiguration+Private.h"

using namespace bugsnag;

@interface RetryQueueTests : FileBasedTest

@end

@implementation RetryQueueTests

static inline dispatch_time_t currentTimeMinusNanoseconds(dispatch_time_t nanoseconds) {
    return (dispatch_time_t)((CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970) * NSEC_PER_SEC) - nanoseconds;
}

- (void)testAddListGetRemove {
    RetryQueue queue(self.filePath);
    __block int errorCallCount = 0;
    queue.setOnFilesystemError(^{
        errorCallCount++;
    });

    OtlpPackage package1(1000, [NSData dataWithBytes:"aaa" length:3], @{@"x": @"y"});
    OtlpPackage package2(1100, [NSData dataWithBytes:"bbb" length:3], @{@"a": @"b"});
    OtlpPackage package3(1110, [NSData dataWithBytes:"ccc" length:3], @{@"1": @"2"});
    queue.add(package1);
    queue.add(package3);
    queue.add(package2);
    // Adding the same timestamp package just overwrites the old one.
    queue.add(package2);
    auto list = queue.list();
    XCTAssertEqual(3U, list.size());
    // List always lists newest to oldest
    XCTAssertEqual(1110U, list[0]);
    XCTAssertEqual(1100U, list[1]);
    XCTAssertEqual(1000U, list[2]);

    auto get1 = queue.get(1000);
    auto get2 = queue.get(1100);
    auto get3 = queue.get(1110);
    XCTAssertTrue(package1 == *get1);
    XCTAssertTrue(package2 == *get2);
    XCTAssertTrue(package3 == *get3);

    queue.remove(1100);
    list = queue.list();
    XCTAssertEqual(2U, list.size());
    XCTAssertEqual(1110U, list[0]);
    XCTAssertEqual(1000U, list[1]);

    // Removing a nonexistent entry is a no-op and does not trigger an error
    queue.remove(1100);
    list = queue.list();
    XCTAssertEqual(2U, list.size());
    XCTAssertEqual(1110U, list[0]);
    XCTAssertEqual(1000U, list[1]);
    XCTAssertEqual(0, errorCallCount);

    queue.remove(1000);
    list = queue.list();
    XCTAssertEqual(1U, list.size());
    XCTAssertEqual(1110U, list[0]);

    queue.remove(1110);
    list = queue.list();
    XCTAssertEqual(0U, list.size());

    XCTAssertEqual(0, errorCallCount);
}

- (void)testCreation {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = false;

    XCTAssertFalse([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);

    RetryQueue queue(self.filePath);
    XCTAssertFalse([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);

    queue.start();
    XCTAssertTrue([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);
    XCTAssertTrue(isDir);
}

- (void)testSweep {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = false;

    RetryQueue queue(self.filePath);
    queue.start();
    XCTAssertTrue([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);
    XCTAssertTrue(isDir);
    __block int callCount = 0;
    queue.setOnFilesystemError(^{
        callCount++;
    });
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"];
    queue.configure(config);

    XCTAssertTrue([[NSData new] writeToFile:[self.filePath stringByAppendingPathComponent:@"xyz.json"] atomically:YES]);
    XCTAssertEqual(1U, [fm contentsOfDirectoryAtPath:self.filePath error:nil].count);
    OtlpPackage package(1, [NSData new], @{});
    queue.add(package);
    XCTAssertEqual(2U, [fm contentsOfDirectoryAtPath:self.filePath error:nil].count);
    OtlpPackage package2(currentTimeMinusNanoseconds(1000), [NSData new], @{});
    queue.add(package2);
    XCTAssertEqual(3U, [fm contentsOfDirectoryAtPath:self.filePath error:nil].count);
    OtlpPackage package3(currentTimeMinusNanoseconds(24*60*60*NSEC_PER_SEC)+10000000, [NSData new], @{});
    queue.add(package3);
    XCTAssertEqual(4U, [fm contentsOfDirectoryAtPath:self.filePath error:nil].count);
    OtlpPackage package4(currentTimeMinusNanoseconds(24*60*60*NSEC_PER_SEC)-1, [NSData new], @{});
    queue.add(package4);
    XCTAssertEqual(5U, [fm contentsOfDirectoryAtPath:self.filePath error:nil].count);

    queue.sweep();
    XCTAssertEqual(0, callCount);
    XCTAssertEqual(2U, [fm contentsOfDirectoryAtPath:self.filePath error:nil].count);
}

- (void)testCreationTopLevelDirAlreadyExists {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = false;

    XCTAssertTrue([fm createDirectoryAtPath:self.filePath withIntermediateDirectories:YES attributes:nil error:nil]);
    XCTAssertTrue([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);
    XCTAssertTrue(isDir);

    RetryQueue queue(self.filePath);
    queue.start();
    XCTAssertTrue([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);
    XCTAssertTrue(isDir);
}

- (void)testFilesystemErrorCallback {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = false;

    // Put a file in place of where RetryQueue will try to create a directory.
    XCTAssertTrue([[NSData new] writeToFile:self.filePath atomically:YES]);
    XCTAssertTrue([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);
    XCTAssertFalse(isDir);

    RetryQueue queue(self.filePath);
    queue.start();
    XCTAssertTrue([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);
    XCTAssertFalse(isDir);

    __block int callCount = 0;
    queue.setOnFilesystemError(^{
        callCount++;
    });

    callCount = 0;
    queue.sweep();
    XCTAssertNotEqual(0, callCount);

    callCount = 0;
    queue.list();
    XCTAssertNotEqual(0, callCount);

    callCount = 0;
    OtlpPackage package(1, [NSData new], @{});
    queue.add(package);
    XCTAssertNotEqual(0, callCount);

    callCount = 0;
    queue.remove(1);
    XCTAssertEqual(0, callCount);
}

@end
