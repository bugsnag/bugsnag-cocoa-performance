//
//  Persistence.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#define BUGSNAG_PERFORMANCE_PERSISTENCE_VERSION @"v1"

#import "Persistence.h"
#import "Filesystem.h"
#import "Utils.h"

using namespace bugsnag;

NSString *bugsnagPerformancePath(NSString *topLevelDir) {
    // Namespace it to the bundle identifier because all MacOS non-sandboxed apps share the same cache dir.
    return [topLevelDir stringByAppendingFormat:@"/bugsnag-performance-%@", [[NSBundle mainBundle] bundleIdentifier]];
}

NSString *bugsnagSharedPath(NSString *topLevelDir) {
    return [topLevelDir stringByAppendingFormat:@"/bugsnag-shared-%@", [[NSBundle mainBundle] bundleIdentifier]];
}

#pragma mark PhasedStartup

void
Persistence::configure(BugsnagPerformanceConfiguration *config) noexcept {
    configuration_ = config;
}

void
Persistence::start() noexcept {
    NSError *error = nil;
    if ((error = [Filesystem ensurePathExists:bugsnagPerformanceDir_]) != nil) {
        BSGLogError(@"error while initializing bugsnag performance persistence dir: %@", error);
    }
    if ((error = [Filesystem ensurePathExists:bugsnagSharedDir_]) != nil) {
        BSGLogError(@"error while initializing bugsnag shared persistence dir: %@", error);
    }
    if (configuration_.internal.clearPersistenceOnStart) {
        clearPerformanceData();
    }
}

#pragma mark Public

NSString *Persistence::bugsnagSharedDir(void) noexcept {
    return bugsnagSharedDir_;
}

NSString *Persistence::bugsnagPerformanceDir(void) noexcept {
    return [bugsnagPerformanceDir_ stringByAppendingPathComponent:BUGSNAG_PERFORMANCE_PERSISTENCE_VERSION];
}

NSError *Persistence::clearPerformanceData(void) noexcept {
    return [Filesystem rebuildPath:bugsnagPerformanceDir_];

    // Note: We don't clear bugsnagSharedDir_ because it's shared with the bugsnag notifier.
}
