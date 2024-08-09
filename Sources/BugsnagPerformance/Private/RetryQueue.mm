//
//  RetryQueue.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 17.01.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "RetryQueue.h"
#import "Filesystem.h"
#import "BugsnagPerformanceConfiguration+Private.h"
#import "Utils.h"
#import <cstdlib>

// No valid file < 24h old will ever have a timestamp of 0.
static const dispatch_time_t INVALID_TIMESTAMP = 0;

using namespace bugsnag;

static NSString *filenameFromTimestamp(dispatch_time_t ts) {
    return [NSString stringWithFormat:@"retry-%019llu.json", ts];
}

/**
 * Get the timestamp that is encoded into a filename.
 * Returns INVALID_TIMESTAMP if the timestamp format is invalid.
 */
static dispatch_time_t timestampFromFilename(NSString *filename) {
    NSError *error = nil;
    NSString *pattern = @"^retry-([0-9]+)\\.json$";
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern: pattern options:0 error:&error];

    auto match = [regex firstMatchInString:filename options:0 range:NSMakeRange(0, filename.length)];
    if (match.range.location == NSNotFound) {
        return INVALID_TIMESTAMP;
    }
    NSRange group1 = [match rangeAtIndex:1];
    NSString *str = [filename substringWithRange:group1];
    return strtoull(str.UTF8String, 0, 10);
}

void RetryQueue::configure(BugsnagPerformanceConfiguration *config) noexcept {
    maxRetryAge_ = intervalToNanoseconds(config.internal.maxRetryAge);
}

void RetryQueue::preStartSetup() noexcept {
    [Filesystem ensurePathExists:baseDir_];
}

void RetryQueue::sweep() noexcept {
    ensureBaseDirExists();
    NSError *error = nil;
    auto contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:baseDir_ error:&error];
    if (contents == nil) {
        BSGLogError(@"error while fetching retry queue contents: %@", error);
        onFilesystemError();
        return;
    }

    const dispatch_time_t currentTime = absoluteTimeToNanoseconds(CFAbsoluteTimeGetCurrent());
    const dispatch_time_t maxAge = maxRetryAge_;

    for (NSString *filename in contents) {
        auto ts = timestampFromFilename(filename);
        // If it's too old or the filename is not what we expect, delete it.
        if (ts == INVALID_TIMESTAMP || ts > currentTime || ts < currentTime - maxAge) {
            remove(filename);
        }
    }
}

std::vector<dispatch_time_t> RetryQueue::list() noexcept {
    ensureBaseDirExists();
    NSError *error = nil;
    std::vector<dispatch_time_t> timestamps;
    auto contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:baseDir_ error:&error];
    if (contents == nil) {
        BSGLogError(@"error while fetching retry queue contents: %@", error);
        onFilesystemError();
    } else {
        for (NSString *filename in contents) {
            auto ts = timestampFromFilename(filename);
            if (ts == INVALID_TIMESTAMP) {
                // Unexpected file. Delete it and carry on.
                remove(filename);
            } else {
                timestamps.push_back(ts);
            }
        }
    }
    std::sort(timestamps.begin(), timestamps.end(), std::greater<>());
    return timestamps;
}

std::unique_ptr<OtlpPackage> RetryQueue::get(dispatch_time_t ts) noexcept {
    // If this fails, we don't care why. Just delete the file.
    NSData *contents = [NSData dataWithContentsOfFile:fullPath(filenameFromTimestamp(ts))
                                              options:0 error:nil];
    if (contents == nil) {
        remove(ts);
        return nullptr;
    }

    // If it's corrupt, just delete the file.
    auto package = deserializeOtlpPackage(ts, contents);
    if (package == nullptr) {
        remove(ts);
    }

    return package;
}

void RetryQueue::add(OtlpPackage &package) noexcept {
    ensureBaseDirExists();
    auto data = package.serialize();
    NSError *error = nil;
    NSString *filePath = fullPath(filenameFromTimestamp(package.timestamp));
    if (![data writeToFile:filePath options:NSDataWritingAtomic error:&error]) {
        BSGLogError(@"error while writing retry file %@: %@", filePath, error);
        onFilesystemError();
    }
}

void RetryQueue::remove(dispatch_time_t ts) noexcept {
    remove(filenameFromTimestamp(ts));
}

void RetryQueue::remove(NSString *filename) noexcept {
    // We don't care if this fails.
    [[NSFileManager defaultManager] removeItemAtPath:fullPath(filename) error:nil];
}

NSString * RetryQueue::fullPath(NSString *filename) noexcept {
    return [baseDir_ stringByAppendingPathComponent:filename];
}

void RetryQueue::ensureBaseDirExists() noexcept {
    NSError *error = [Filesystem ensurePathExists:baseDir_];
    if (error != nil) {
        BSGLogError(@"error while creating base dir %@: %@", baseDir_, error);
        onFilesystemError();
    }
}
