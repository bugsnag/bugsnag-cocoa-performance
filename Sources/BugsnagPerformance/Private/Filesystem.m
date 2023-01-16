//
//  Filesystem.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 17.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "Filesystem.h"

@implementation Filesystem

+ (NSError *)ensurePathExists:(NSString *)path {
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    return error;
}

+ (NSError *)rebuildPath:(NSString *)path {
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path]) {
        [fm removeItemAtPath:path error:&error];
        if (error != nil) {
            return error;
        }
    }
    return [self ensurePathExists:path];
}

@end
