//
//  Filesystem.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 17.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Filesystem : NSObject

/**
 * Builds all necessary intervening directories to make the given directory path exist.
 */
+ ( NSError * _Nullable )ensurePathExists:(NSString *)path;

/**
 * Deletes the given path and recreates it (as a directory).
 */
+ ( NSError * _Nullable )rebuildPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
