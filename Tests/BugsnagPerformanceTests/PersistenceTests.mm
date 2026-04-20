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

// Helper to list non-hidden entries in a directory
static NSArray<NSString *> *visibleContents(NSString *path) {
    NSError *err = nil;
    NSArray<NSString *> *all = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&err];
    if (all == nil) {
        return @[];
    }
    NSMutableArray<NSString *> *res = [NSMutableArray array];
    for (NSString *name in all) {
        if (![name hasPrefix:@"."]) {
            [res addObject:name];
        }
    }
    return res;
}

- (void)testBugsnagPerformancePersistence {
    auto fm = [NSFileManager defaultManager];
    BOOL isDir = false;
    NSError *error = nil;
    NSString *expectedBasePath = [self.filePath stringByAppendingPathComponent:
                                  [NSString stringWithFormat:@"bugsnag-performance-%@",
                                   NSBundle.mainBundle.bundleIdentifier]];
    // Construct in-place to avoid copy/move (std::atomic member deletes copy ctor).
    Persistence persistence(self.filePath);
    XCTAssertEqualObjects([expectedBasePath stringByAppendingPathComponent:@"v1"], persistence.bugsnagPerformanceDir());
    // Constructor probes and creates the performance dir, so it should exist already.
    XCTAssertTrue([fm fileExistsAtPath:expectedBasePath isDirectory:&isDir]);
    XCTAssertTrue(isDir);

    NSArray *visible = visibleContents(expectedBasePath);
    // Constructor creates the versioned subdirectory (v1) inside the top-level performance dir.
    XCTAssertEqual(1U, visible.count);
    XCTAssertEqualObjects(@"v1", visible[0]);
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
    // Construct in-place to avoid copy/move (std::atomic member deletes copy ctor).
    Persistence persistence(self.filePath);
    XCTAssertEqualObjects(expectedBasePath, persistence.bugsnagSharedDir());
    // Constructor probes and creates the shared dir as well.
    XCTAssertTrue([fm fileExistsAtPath:expectedBasePath isDirectory:&isDir]);
    XCTAssertTrue(isDir);
    NSArray *visibleShared = visibleContents(expectedBasePath);
    XCTAssertEqual(0U, visibleShared.count);
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
