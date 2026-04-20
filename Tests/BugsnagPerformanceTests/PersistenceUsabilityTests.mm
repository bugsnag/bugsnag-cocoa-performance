#import "FileBasedTest.h"
#import "Persistence.h"

using namespace bugsnag;

@interface PersistenceUsabilityTests : FileBasedTest

@end

@implementation PersistenceUsabilityTests

- (void)setPermissions:(mode_t)perm atPath:(NSString *)path {
    NSDictionary *attrs = @{NSFilePosixPermissions: @(perm)};
    [[NSFileManager defaultManager] setAttributes:attrs ofItemAtPath:path error:nil];
}

- (void)testTopLevelDirNotWritableMakesPersistenceUnusable {
    NSFileManager *fm = [NSFileManager defaultManager];
    // Ensure top-level directory exists and then remove write permission
    XCTAssertTrue([fm createDirectoryAtPath:self.filePath withIntermediateDirectories:YES attributes:nil error:nil]);
    // make read-only
    [self setPermissions:0444 atPath:self.filePath];

    // Construct Persistence which will attempt to create subdirs under top-level; should fail
    Persistence persistence(self.filePath);
    XCTAssertFalse(persistence.isUsable());

    // restore permissions so tearDown can remove
    [self setPermissions:0755 atPath:self.filePath];
}

- (void)testRetryQueueSubdirNotWritableMakesPersistenceUnusable {
    NSFileManager *fm = [NSFileManager defaultManager];
    // Create top-level and performance/v1/retry-queue, then make retry-queue read-only
    NSString *perfBase = [self.filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"bugsnag-performance-%@", NSBundle.mainBundle.bundleIdentifier]];
    NSString *versioned = [perfBase stringByAppendingPathComponent:@"v1"];
    NSString *retryQueue = [versioned stringByAppendingPathComponent:@"retry-queue"];

    XCTAssertTrue([fm createDirectoryAtPath:retryQueue withIntermediateDirectories:YES attributes:nil error:nil]);
    // Make retry-queue dir read-only (no write permission)
    [self setPermissions:0555 atPath:retryQueue];

    Persistence persistence(self.filePath);
    XCTAssertFalse(persistence.isUsable());

    // restore permissions so tearDown can remove
    [self setPermissions:0755 atPath:retryQueue];
}

- (void)testSharedDirNotWritableMakesPersistenceUnusable {
    NSFileManager *fm = [NSFileManager defaultManager];
    // Ensure top-level exists and create the shared dir path and make it not writable
    NSString *sharedBase = [self.filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"bugsnag-shared-%@", NSBundle.mainBundle.bundleIdentifier]];
    XCTAssertTrue([fm createDirectoryAtPath:sharedBase withIntermediateDirectories:YES attributes:nil error:nil]);
    [self setPermissions:0444 atPath:sharedBase];

    Persistence persistence(self.filePath);
    XCTAssertFalse(persistence.isUsable());

    [self setPermissions:0755 atPath:sharedBase];
}

@end
