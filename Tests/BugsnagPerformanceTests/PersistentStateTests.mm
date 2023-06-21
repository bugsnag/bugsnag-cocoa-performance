//
//  PersistentStateTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 11.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "FileBasedTest.h"

#import "PersistentState.h"
#import "BugsnagPerformanceConfiguration+Private.h"

using namespace bugsnag;

@interface PersistentStateTests : FileBasedTest

@end

@implementation PersistentStateTests

- (std::shared_ptr<PersistentState>)persistentStateWithConfig:(BugsnagPerformanceConfiguration *)config {
    auto persistence = std::make_shared<Persistence>(self.filePath);
    auto persistentState = std::make_shared<PersistentState>(persistence);
    persistentState->earlyConfigure([BSGEarlyConfiguration new]);
    persistentState->earlySetup();
    persistentState->configure(config);
    persistence->start();
    // Don't start persistentState yet...
    return persistentState;
}

- (void)testPersistentState {
    NSString *expectedPath = [self.filePath stringByAppendingPathComponent:
                                  [NSString stringWithFormat:@"bugsnag-performance-%@/v1/persistent-state.json",
                                   NSBundle.mainBundle.bundleIdentifier]];

    auto fm = [NSFileManager defaultManager];
    auto config = [[BugsnagPerformanceConfiguration alloc] initWithApiKey:@"0123456789abcdef0123456789abcdef"];

    XCTAssertFalse([fm fileExistsAtPath:expectedPath]);

    auto state = [self persistentStateWithConfig:config];

    // Default BugsnagPerformanceConfiguration probability is 1
    XCTAssertEqual(1, state->probability());

    // File gets created on start()
    XCTAssertFalse([fm fileExistsAtPath:expectedPath]);
    state->start();
    XCTAssertTrue([fm fileExistsAtPath:expectedPath]);
    XCTAssertEqual(1, state->probability());

    config.internal.initialSamplingProbability = 0.1;
    state = [self persistentStateWithConfig:config];
    // pre-start probability uses config
    XCTAssertEqual(0.1, state->probability());
    // start() loads persisted data, which overrides config probability
    state->start();
    XCTAssertEqual(1, state->probability());

    // Corrupt or missing file reverts to the config probability
    [fm removeItemAtPath:expectedPath error:nil];
    config.internal.initialSamplingProbability = 0.1;
    state = [self persistentStateWithConfig:config];
    state->start();
    XCTAssertEqual(0.1, state->probability());

    // Multiple changes are properly reflected
    state->setProbability(0.5);
    XCTAssertEqual(0.5, state->probability());
    state->setProbability(0.6);
    XCTAssertEqual(0.6, state->probability());

    // ... even after reload
    config.internal.initialSamplingProbability = 0.1;
    state = [self persistentStateWithConfig:config];
    state->start();
    XCTAssertEqual(0.6, state->probability());
}

@end
