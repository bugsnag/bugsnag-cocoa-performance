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

- (void)testPersistence {
    auto fm = [NSFileManager defaultManager];
    BOOL isDir = false;
    NSError *error = nil;
    auto persistence = Persistence(self.filePath);
    XCTAssertFalse([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);
    XCTAssertEqualObjects([self.filePath stringByAppendingPathComponent:@"v1"], persistence.topLevelDirectory());

    XCTAssertNil(persistence.start());
    XCTAssertTrue([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);
    XCTAssertTrue(isDir);
    XCTAssertEqual(0U, [fm contentsOfDirectoryAtPath:self.filePath error:&error].count);
    XCTAssertNil(error);

    auto internalFile = [self.filePath stringByAppendingPathComponent:@"a"];
    XCTAssertTrue([[@"a" dataUsingEncoding:NSUTF8StringEncoding]
                   writeToFile:internalFile
                   atomically:YES]);
    XCTAssertTrue([fm fileExistsAtPath:internalFile isDirectory:&isDir]);
    XCTAssertFalse(isDir);

    persistence.clear();
    XCTAssertTrue([fm fileExistsAtPath:self.filePath isDirectory:&isDir]);
    XCTAssertTrue(isDir);
    XCTAssertEqual(0U, [fm contentsOfDirectoryAtPath:self.filePath error:&error].count);
    XCTAssertNil(error);
    XCTAssertFalse([fm fileExistsAtPath:internalFile isDirectory:&isDir]);
}

@end
