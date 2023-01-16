//
//  FilesystemTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 17.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "FileBasedTest.h"
#import "Filesystem.h"

@interface FilesystemTests : FileBasedTest

@end

@implementation FilesystemTests

- (void)testFilesystem {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL isDir = false;
    NSString *subdir = [self.filePath stringByAppendingPathComponent:@"subdir"];

    
    XCTAssertFalse([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);
    XCTAssertFalse([fm fileExistsAtPath:subdir isDirectory:&isDir]);
    XCTAssertNil([Filesystem ensurePathExists:self.filePath]);
    XCTAssertTrue([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);
    XCTAssertTrue(isDir);
    XCTAssertFalse([fm fileExistsAtPath:subdir isDirectory:&isDir]);
    XCTAssertNil([Filesystem ensurePathExists:subdir]);
    XCTAssertTrue([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);
    XCTAssertTrue(isDir);
    XCTAssertTrue([fm fileExistsAtPath:subdir isDirectory:&isDir]);
    XCTAssertTrue(isDir);

    XCTAssertNil([Filesystem rebuildPath:self.filePath]);
    XCTAssertTrue([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);
    XCTAssertTrue(isDir);
    XCTAssertFalse([fm fileExistsAtPath:subdir isDirectory:&isDir]);

    XCTAssertNil([Filesystem ensurePathExists:subdir]);
    XCTAssertTrue([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);
    XCTAssertTrue(isDir);
    XCTAssertTrue([fm fileExistsAtPath:subdir isDirectory:&isDir]);
    XCTAssertTrue(isDir);

    XCTAssertEqual(1, [fm contentsOfDirectoryAtPath:self.filePath error:&error].count);
    XCTAssertNil(error);
    XCTAssertEqual(0, [fm contentsOfDirectoryAtPath:subdir error:&error].count);
    XCTAssertNil(error);

    NSString *internalFile = [subdir stringByAppendingPathComponent:@"a"];
    XCTAssertTrue([[@"a" dataUsingEncoding:NSUTF8StringEncoding]
                   writeToFile:internalFile
                   atomically:YES]);
    XCTAssertTrue([fm fileExistsAtPath:internalFile isDirectory:&isDir]);
    XCTAssertFalse(isDir);

    XCTAssertNil([Filesystem rebuildPath:self.filePath]);
    XCTAssertTrue([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);
    XCTAssertTrue(isDir);
    XCTAssertFalse([fm fileExistsAtPath:subdir isDirectory:&isDir]);
    XCTAssertFalse([fm fileExistsAtPath:internalFile isDirectory:&isDir]);
}

- (void)testRebuild {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = false;
    NSString *subdir = [self.filePath stringByAppendingPathComponent:@"subdir"];
    
    
    XCTAssertFalse([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);
    XCTAssertFalse([fm fileExistsAtPath:subdir isDirectory:&isDir]);
    
    XCTAssertNil([Filesystem rebuildPath:self.filePath]);
    XCTAssertTrue([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);
}

@end
