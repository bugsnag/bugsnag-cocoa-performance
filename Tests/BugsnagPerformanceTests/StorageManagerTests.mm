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

// Tests use per-instance dependency injection to simulate filesystem behaviour.

@interface StorageManagerTests : FileBasedTest
@end

@implementation StorageManagerTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // no global cleanup required
    [super tearDown];
}

// Directory creation succeeds – normal behaviour
- (void)testDirectoryCreationSucceeds {
    __block BOOL errorCallbackCalled = NO;
    bugsnag::RetryQueue queue(self.filePath);
    std::atomic_bool shouldFail(false);
    queue.setEnsurePathExistsHandler([&shouldFail](NSString *path) -> NSError * {
        if (shouldFail.load()) {
            return [NSError errorWithDomain:@"test" code:1 userInfo:nil];
        }
        return [Filesystem ensurePathExists:path];
    });
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
    XCTAssertTrue(contents.count >= 1); // Directory may be empty if add() is async
}

// Directory creation fails at startup – storage disabled flag set
- (void)testDirectoryCreationFailsStorageDisabled {
    // This is a flag we will flip to YES if RetryQueue reports a filesystem error.
    // `__block` allows the block we pass to setOnFilesystemError to modify it.
    __block BOOL errorCallbackCalled = NO;

    // Create a RetryQueue that will store retry JSON files under `self.filePath`.
    // In normal operation, this directory must exist (or be created) before files can be written.
    bugsnag::RetryQueue queue(self.filePath);

    // A shared flag used by our injected "ensure directory exists" handler.
    // We set it to true so directory creation will *fail* in this test.
    std::atomic_bool shouldFail(true);

    // Inject a custom directory-creation function into RetryQueue.
    // RetryQueue calls this to ensure its base directory exists.
    //
    // In this test, when shouldFail==true we return an NSError to simulate
    // "cannot create directory" (permission denied / path invalid / etc).
    queue.setEnsurePathExistsHandler([&shouldFail](NSString *path) -> NSError * {
        if (shouldFail.load()) {
            // Simulate a filesystem failure when creating/ensuring the directory.
            return [NSError errorWithDomain:@"test" code:1 userInfo:nil];
        }

        // If shouldFail was false, we'd call the real implementation.
        return [Filesystem ensurePathExists:path];
    });

    // Provide the callback RetryQueue should call when it encounters a filesystem error.
    // In this test we flip `errorCallbackCalled` to prove the callback happened.
    queue.setOnFilesystemError(^{ errorCallbackCalled = YES; });

    // Configure queue settings (max retry age etc). API key is required by config object.
    queue.configure([[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"]);

    // Perform startup setup. This is expected to try to create/ensure the base directory.
    // Because shouldFail==true, directory creation will fail here and the queue should
    // mark persistence as unusable (depending on your new latch behavior).
    queue.preStartSetup();

    // Call sweep(). sweep() normally lists the directory and deletes old/corrupt retry files.
    // The key assertion here is: even if storage is unavailable, sweep() should not throw/crash.
    XCTAssertNoThrow(queue.sweep());

    // We expect the filesystem error callback to be invoked (at least once) because we forced
    // directory creation to fail. With the new "notify once" behavior, this should be exactly once.
    XCTAssertTrue(errorCallbackCalled);

    // Verify the directory was NOT created (because our ensurePath handler always failed).
    BOOL isDir = NO;
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:self.filePath isDirectory:&isDir]);
    
    auto list = queue.list();
    XCTAssertEqual(0U, list.size());
}

// Directory creation fails – no subsequent file writes attempted
- (void)testNoFileWritesAfterDirCreationFailure {
    __block int errorCallbackCount = 0;
    bugsnag::RetryQueue queue(self.filePath);
    std::atomic_bool shouldFail(true);
    queue.setEnsurePathExistsHandler([&shouldFail](NSString *path) -> NSError * {
        if (shouldFail.load()) {
            return [NSError errorWithDomain:@"test" code:1 userInfo:nil];
        }
        return [Filesystem ensurePathExists:path];
    });
    queue.setOnFilesystemError(^{ errorCallbackCount++; });
    queue.configure([[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"]);
    queue.preStartSetup();
    queue.sweep();
    
    bugsnag::OtlpPackage package(1, [@"testdata" dataUsingEncoding:NSUTF8StringEncoding], @{});
    queue.add(package);
    
    // Error callback may be called twice: once for sweep, once for add
    XCTAssertTrue(errorCallbackCount >= 1);
    BOOL isDir = NO;
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:self.filePath isDirectory:&isDir]);
}

// Directory creation fails – directory creation attempts should NOT repeat (storage disabled)
- (void)testNoRepeatedDirCreationAttempts {
    __block int errorCallbackCount = 0;

    bugsnag::RetryQueue queue(self.filePath);
    std::atomic_bool shouldFail(true);

    int ensureCalls = 0;
    queue.setEnsurePathExistsHandler([&shouldFail, &ensureCalls](NSString *path) -> NSError * {
        ensureCalls++;
        if (shouldFail.load()) {
            return [NSError errorWithDomain:@"test" code:1 userInfo:nil];
        }
        return [Filesystem ensurePathExists:path];
    });

    queue.setOnFilesystemError(^{ errorCallbackCount++; });
    queue.configure([[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"11111111111111111111111111111111"]);

    queue.preStartSetup();
    queue.sweep();
    queue.sweep();

    // New behavior: only the startup attempt occurs; later calls do not retry filesystem ops
    XCTAssertEqual(1, ensureCalls);

    // New behavior: notify once (or at least once) and then stop spamming
    XCTAssertEqual(1, errorCallbackCount);

    BOOL isDir = NO;
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:self.filePath isDirectory:&isDir]);
}

@end
