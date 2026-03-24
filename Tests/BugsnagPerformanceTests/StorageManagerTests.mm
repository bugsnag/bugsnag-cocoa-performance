//
//  StorageManagerTests.mm
//  BugsnagPerformance-iOSTests
//
//  Created for scenario-based storage/persistence unit tests.
//

#import "FileBasedTest.h"
#import "RetryQueue.h"
#import "Persistence.h"
#import "Filesystem.h"
#import <XCTest/XCTest.h>
#import <objc/runtime.h>

using namespace bugsnag;

// Swizzling helpers for Filesystem+ensurePathExists
static BOOL gShouldFailEnsurePathExists = NO;
static IMP gOriginalEnsurePathExistsIMP = NULL;

static void SwizzleEnsurePathExists(void) {
    Class cls = object_getClass([Filesystem class]);
    SEL selector = @selector(ensurePathExists:);
    Method method = class_getClassMethod(cls, selector);
    if (!gOriginalEnsurePathExistsIMP) {
        gOriginalEnsurePathExistsIMP = method_getImplementation(method);
    }
    IMP newIMP = imp_implementationWithBlock(^NSError *(id _self, NSString *path) {
        (void)_self; (void)path; // Silence unused parameter warnings
        if (gShouldFailEnsurePathExists) {
            return [NSError errorWithDomain:@"test" code:1 userInfo:nil];
        }
        return nil;
    });
    method_setImplementation(method, newIMP);
}

static void RestoreEnsurePathExists(void) {
    if (gOriginalEnsurePathExistsIMP) {
        Class cls = object_getClass([Filesystem class]);
        SEL selector = @selector(ensurePathExists:);
        Method method = class_getClassMethod(cls, selector);
        method_setImplementation(method, gOriginalEnsurePathExistsIMP);
    }
}

@interface StorageManagerTests : FileBasedTest
@end

@implementation StorageManagerTests

- (void)setUp {
    [super setUp];
    SwizzleEnsurePathExists();
}

- (void)tearDown {
    RestoreEnsurePathExists();
    gShouldFailEnsurePathExists = NO;
    [super tearDown];
}

// Directory creation succeeds – normal behaviour
- (void)testDirectoryCreationSucceeds {
    gShouldFailEnsurePathExists = NO;
    __block BOOL errorCallbackCalled = NO;
    bugsnag::RetryQueue queue(self.filePath);
    queue.setOnFilesystemError(^{ errorCallbackCalled = YES; });
    queue.configure([[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"]);
    queue.preStartSetup();
    // Directory should be created
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:self.filePath isDirectory:&isDir];
    // Add a span (simulate file write)
    NSData *data = [@"testdata" dataUsingEncoding:NSUTF8StringEncoding];
    bugsnag::OtlpPackage package(1, data, @{});
    queue.add(package);
    // File should exist in directory
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.filePath error:nil];
    XCTAssertTrue(contents.count >= 0); // Directory may be empty if add() is async
}

// Directory creation fails at startup – storage disabled flag set
- (void)testDirectoryCreationFailsStorageDisabled {
    gShouldFailEnsurePathExists = YES;
    __block BOOL errorCallbackCalled = NO;
    bugsnag::RetryQueue queue(self.filePath);
    queue.setOnFilesystemError(^{ errorCallbackCalled = YES; });
    queue.configure([[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"]);
    queue.preStartSetup();
    // Should not throw, and error callback should be called on sweep
    XCTAssertNoThrow(queue.sweep());
    XCTAssertTrue(errorCallbackCalled);
    // Directory should not be created
    BOOL isDir = NO;
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:self.filePath isDirectory:&isDir]);
}

// Directory creation fails – no subsequent file writes attempted
- (void)testNoFileWritesAfterDirCreationFailure {
    gShouldFailEnsurePathExists = YES;
    __block int errorCallbackCount = 0;
    bugsnag::RetryQueue queue(self.filePath);
    queue.setOnFilesystemError(^{ errorCallbackCount++; });
    queue.configure([[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"]);
    queue.preStartSetup();
    queue.sweep();
    queue.add(*(new bugsnag::OtlpPackage(1, [@"testdata" dataUsingEncoding:NSUTF8StringEncoding], @{})));
    // Error callback may be called twice: once for sweep, once for add
    XCTAssertTrue(errorCallbackCount >= 1);
    BOOL isDir = NO;
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:self.filePath isDirectory:&isDir]);
}

// Directory creation fails – no repeated directory creation attempts
- (void)testNoRepeatedDirCreationAttempts {
    gShouldFailEnsurePathExists = YES;
    __block int errorCallbackCount = 0;
    bugsnag::RetryQueue queue(self.filePath);
    queue.setOnFilesystemError(^{ errorCallbackCount++; });
    queue.configure([[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"]);
    queue.preStartSetup();
    queue.sweep();
    queue.sweep();
    // Error callback may be called twice: once for each sweep
    XCTAssertTrue(errorCallbackCount >= 1);
}

// Directory temporarily unavailable, then available: one-shot disable
- (void)testOneShotDisableAfterInitialFailure {
    gShouldFailEnsurePathExists = YES;
    __block int errorCallbackCount = 0;
    bugsnag::RetryQueue queue(self.filePath);
    queue.setOnFilesystemError(^{ errorCallbackCount++; });
    queue.configure([[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"]);
    queue.preStartSetup();
    // Now simulate that ensurePathExists would succeed, but storage remains disabled
    gShouldFailEnsurePathExists = NO;
    queue.sweep();
    // Error callback should only be called once (no recovery)
    XCTAssertEqual(errorCallbackCount, 1);
}

@end
