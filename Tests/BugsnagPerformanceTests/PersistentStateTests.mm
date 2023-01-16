//
//  PersistentStateTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 11.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "FileBasedTest.h"

#import "PersistentState.h"

using namespace bugsnag;

@interface PersistentStateTests : FileBasedTest

@end

@implementation PersistentStateTests

- (void)testPersistentState {
    auto fm = [NSFileManager defaultManager];
    __block int callbackCallCount = false;

    auto state = PersistentState(self.filePath, ^{
        callbackCallCount++;
    });

    XCTAssertEqual(0, state.probability());
    XCTAssertFalse([fm fileExistsAtPath:self.filePath]);
    XCTAssertEqual(0, callbackCallCount);

    state.setProbability(0.5);
    XCTAssertEqual(0.5, state.probability());
    XCTAssertFalse([fm fileExistsAtPath:self.filePath]);
    XCTAssertEqual(1, callbackCallCount);

    state.setProbability(0.6);
    XCTAssertEqual(0.6, state.probability());
    XCTAssertFalse([fm fileExistsAtPath:self.filePath]);
    XCTAssertEqual(2, callbackCallCount);

    state.persist();
    XCTAssertTrue([fm fileExistsAtPath:self.filePath]);

    callbackCallCount = 0;
    state = PersistentState(self.filePath, ^{
        callbackCallCount++;
    });
    XCTAssertEqual(0, state.probability());
    XCTAssertNil(state.load());
    XCTAssertEqual(0.6, state.probability());
    XCTAssertTrue([fm fileExistsAtPath:self.filePath]);
    XCTAssertEqual(0, callbackCallCount);
}

@end
