//
//  PersistenceTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 11.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "FileBasedTest.h"
#import "Persistence.h"

using namespace bugsnag;

@interface PersistenceTests : FileBasedTest

@end

@implementation PersistenceTests

- (void)testBugsnagPerformancePersistence {
    auto fm = [NSFileManager defaultManager];
    BOOL isDir = false;
    NSError *error = nil;
    NSString *expectedBasePath = [self.filePath stringByAppendingPathComponent:
                                  [NSString stringWithFormat:@"bugsnag-performance-%@",
                                   NSBundle.mainBundle.bundleIdentifier]];
    auto persistence = Persistence(self.filePath);
    XCTAssertEqualObjects([expectedBasePath stringByAppendingPathComponent:@"v1"], persistence.bugsnagPerformanceDir());
    XCTAssertFalse([fm fileExistsAtPath:expectedBasePath isDirectory:&isDir]);

    persistence.start();
    XCTAssertTrue([fm fileExistsAtPath:expectedBasePath isDirectory:&isDir]);
    XCTAssertTrue(isDir);
    XCTAssertEqual(0U, [fm contentsOfDirectoryAtPath:expectedBasePath error:&error].count);
    XCTAssertNil(error);

    auto internalFile = [expectedBasePath stringByAppendingPathComponent:@"a"];
    XCTAssertTrue([[@"a" dataUsingEncoding:NSUTF8StringEncoding]
                   writeToFile:internalFile
                   atomically:YES]);
    XCTAssertTrue([fm fileExistsAtPath:internalFile isDirectory:&isDir]);
    XCTAssertFalse(isDir);

    persistence.clearPerformanceData();
    XCTAssertTrue([fm fileExistsAtPath:expectedBasePath isDirectory:&isDir]);
    XCTAssertTrue(isDir);
    XCTAssertEqual(0U, [fm contentsOfDirectoryAtPath:expectedBasePath error:&error].count);
    XCTAssertNil(error);
    XCTAssertFalse([fm fileExistsAtPath:internalFile isDirectory:&isDir]);
}

- (void)testBugsnagSharedPersistence {
    auto fm = [NSFileManager defaultManager];
    BOOL isDir = false;
    NSError *error = nil;
    NSString *expectedBasePath = [self.filePath stringByAppendingPathComponent:
                                  [NSString stringWithFormat:@"bugsnag-shared-%@",
                                   NSBundle.mainBundle.bundleIdentifier]];
    auto persistence = Persistence(self.filePath);
    XCTAssertEqualObjects(expectedBasePath, persistence.bugsnagSharedDir());
    XCTAssertFalse([fm fileExistsAtPath:expectedBasePath isDirectory:&isDir]);

    persistence.start();
    XCTAssertTrue([fm fileExistsAtPath:expectedBasePath isDirectory:&isDir]);
    XCTAssertTrue(isDir);
    XCTAssertEqual(0U, [fm contentsOfDirectoryAtPath:expectedBasePath error:&error].count);
    XCTAssertNil(error);

    auto internalFile = [expectedBasePath stringByAppendingPathComponent:@"a"];
    XCTAssertTrue([[@"a" dataUsingEncoding:NSUTF8StringEncoding]
                   writeToFile:internalFile
                   atomically:YES]);
    XCTAssertTrue([fm fileExistsAtPath:internalFile isDirectory:&isDir]);
    XCTAssertFalse(isDir);

    // clear() does NOT clear the shared directory!
    persistence.clearPerformanceData();
    XCTAssertTrue([fm fileExistsAtPath:expectedBasePath isDirectory:&isDir]);
    XCTAssertTrue(isDir);
    XCTAssertEqual(1U, [fm contentsOfDirectoryAtPath:expectedBasePath error:&error].count);
    XCTAssertNil(error);
    XCTAssertTrue([fm fileExistsAtPath:internalFile isDirectory:&isDir]);
}

@end
