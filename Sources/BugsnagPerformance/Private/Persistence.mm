//
//  Persistence.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#define PERSISTENCE_VERSION @"v1"

#import "Persistence.h"
#import "Filesystem.h"
#import "Utils.h"

using namespace bugsnag;

void Persistence::start() noexcept {
    NSError *error = nil;
    if ((error = [Filesystem ensurePathExists:topLevelDir_]) != nil) {
        BSGLogError(@"error while initializing persistence: %@", error);
    }
}

NSString *Persistence::topLevelDirectory(void) noexcept {
    return [topLevelDir_ stringByAppendingPathComponent:PERSISTENCE_VERSION];
}

NSError *Persistence::clear(void) noexcept {
    return [Filesystem rebuildPath:topLevelDir_];
}
