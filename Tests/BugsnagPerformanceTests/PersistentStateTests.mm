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
    // Don't do preStartSetup or start yet...
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

    // File gets created at preStartSetup()
    XCTAssertFalse([fm fileExistsAtPath:expectedPath]);
    state->preStartSetup();
    XCTAssertTrue([fm fileExistsAtPath:expectedPath]);
    XCTAssertEqual(1, state->probability());
    state->start();

    config.internal.initialSamplingProbability = 0.1;
    state = [self persistentStateWithConfig:config];
    // pre-start probability uses config
    XCTAssertEqual(0.1, state->probability());
    // preStartSetup() loads persisted data, which overrides config probability
    state->preStartSetup();
    XCTAssertEqual(1, state->probability());
    state->start();

    // Corrupt or missing file reverts to the config probability
    [fm removeItemAtPath:expectedPath error:nil];
    config.internal.initialSamplingProbability = 0.1;
    state = [self persistentStateWithConfig:config];
    state->preStartSetup();
    XCTAssertEqual(0.1, state->probability());
    state->start();

    // Multiple changes are properly reflected
    state->setProbability(0.5);
    XCTAssertEqual(0.5, state->probability());
    state->setProbability(0.6);
    XCTAssertEqual(0.6, state->probability());
    state->start();

    // ... even after reload
    config.internal.initialSamplingProbability = 0.1;
    state = [self persistentStateWithConfig:config];
    state->preStartSetup();
    XCTAssertEqual(0.6, state->probability());
    state->start();
}

@end
