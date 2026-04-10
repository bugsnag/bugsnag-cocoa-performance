//
//  Utils.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 08/11/2022.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import "Logging.h"

namespace bugsnag {

// Use NaN to signal an invalid/unset CFAbsoluteTime.
// WARNING: Do not compare to this value! (NAN == NAN) is always FALSE for ieee754 float.
// Use isCFAbsoluteTimeValid() instead.
static const CFAbsoluteTime CFABSOLUTETIME_INVALID = NAN;

static inline bool isCFAbsoluteTimeValid(CFAbsoluteTime time) {
    return !isnan(time);
}

template<typename T>
static inline T *BSGDynamicCast(__unsafe_unretained id obj) {
    if ([obj isKindOfClass:[T class]]) {
        return obj;
    }
    return nil;
}

/**
 * Convert an NSDate into a CFAbsoluteTime.
 * CFAbsoluteTime is a double containing the number of seconds since (00:00:00 1 January 2001).
 */
static inline CFAbsoluteTime dateToAbsoluteTime(NSDate *date) {
    return date ? date.timeIntervalSinceReferenceDate : CFABSOLUTETIME_INVALID;
}

/**
 * Convert a struct timeval to a CFAbsoluteTime.
 * struct timeval is the number of seconds and microseconds since (00:00:00 1 January 1970).
 * CFAbsoluteTime is a double containing the number of seconds since (00:00:00 1 January 2001).
 */
static inline CFAbsoluteTime timevalToAbsoluteTime(struct timeval &tv) {
    CFAbsoluteTime time = CFAbsoluteTime(tv.tv_sec) + (CFAbsoluteTime(tv.tv_usec) / USEC_PER_SEC);
    return time - kCFAbsoluteTimeIntervalSince1970;
}

/**
 * Convert a CFAbsoluteTime to a dispatch_time_t.
 * CFAbsoluteTime is a double containing the number of seconds since (00:00:00 1 January 2001).
 * dispatch_time_t is the number of nanoseconds since (00:00:00 1 January 1970).
 */
static inline dispatch_time_t absoluteTimeToNanoseconds(CFAbsoluteTime time) {
    return (dispatch_time_t) ((time + kCFAbsoluteTimeIntervalSince1970) * NSEC_PER_SEC);
}

/**
 * Convert an NSTimeInterval to a dispatch_time_t.
 * NSTimeInterval is a double containing the time interval in seconds.
 * dispatch_time_t is the time interval in nanoseconds.
 */
static inline dispatch_time_t intervalToNanoseconds(NSTimeInterval interval) {
    return (dispatch_time_t) (interval * NSEC_PER_SEC);
}

/**
 * Try to fetch the original request from a task. Fills out error if the task throws an exception and we can't get the request.
 *
 * This function is necessary because Apple deliberately breaks their own public API by throwing an exception
 * to signal that something isn't supported by a particular subclass (and also doesn't document this).
 */
static inline NSURLRequest *getTaskOriginalRequest(NSURLSessionTask *task, NSError **error) {
    NSURLRequest *req = nil;

    try {
        req = task.originalRequest;
        BSGLogTrace(@"Fetched originalRequest %@ from task %@", req, task);
    } catch(NSException *e) {
        if (error != nil) {
            NSString *errorDesc = [NSString stringWithFormat:
                                   @"%@ threw exception while accessing originalRequest: %@",
                                   task.class, e];
            *error = [NSError errorWithDomain:@"com.bugsnag.bugsnag-cocoa-performance"
                                         code:100
                                     userInfo:@{NSLocalizedDescriptionKey:errorDesc}];
            BSGLogTrace(@"Failed to fetch originalRequest from task %@: %@", task, *error);
        }
    }

    return req;
}

/**
 * Try to fetch the current request from a task. Fills out error
 * if the task throws an exception and we can't get the request.
 *
 * This function is necessary because Apple deliberately breaks their own public API by throwing an exception
 * to signal that something isn't supported by a particular subclass (and also doesn't document this).
 */
static inline NSURLRequest *getTaskCurrentRequest(NSURLSessionTask *task, NSError **error) {
    NSURLRequest *req = nil;

    try {
        req = task.currentRequest;
        BSGLogTrace(@"Fetched currentRequest %@ from task %@", req, task);
    } catch(NSException *e) {
        if (error != nil) {
            NSString *errorDesc = [NSString stringWithFormat:
                                   @"%@ threw exception while accessing currentRequest: %@",
                                   task.class, e];
            *error = [NSError errorWithDomain:@"com.bugsnag.bugsnag-cocoa-performance"
                                         code:100
                                     userInfo:@{NSLocalizedDescriptionKey:errorDesc}];
            BSGLogTrace(@"Failed to fetch currentRequest from task %@: %@", task, *error);
        }
    }

    return req;
}

/**
 * Try to fetch the original request from a task, falling back to the current request. Fills out error
 * if the task throws an exception and we can't get the request.
 *
 * This function is necessary because Apple deliberately breaks their own public API by throwing an exception
 * to signal that something isn't supported by a particular subclass (and also doesn't document this).
 */
static inline NSURLRequest *getTaskRequest(NSURLSessionTask *task, NSError **error) {
    NSURLRequest *req = getTaskOriginalRequest(task, error);
    if (req != nil) {
        return req;
    }
    return getTaskCurrentRequest(task, error);
}

// Normalizes URL path so "/v1/traces" and "/v1/traces/" are treated as the same.
// Also ensures empty/nil paths become "/".
static inline NSString *BSGNormalizePath(NSString *p) {
    // If the path is nil or empty, treat it as root "/"
    if (p == nil || p.length == 0) return @"/";

    // If it's already "/", return it as-is
    if ([p isEqualToString:@"/"]) return @"/";

    // If path ends with "/", remove the trailing slash
    // Example: "/v1/traces/" -> "/v1/traces"
    if ([p hasSuffix:@"/"]) {
        p = [p substringToIndex:p.length - 1];

        // If removing "/" makes it empty, treat it as root
        if (p.length == 0) return @"/";
    }

    // Return the normalized path
    return p;
}

// Returns an explicit port number for a URL.
//
// - If URL explicitly contains a port (e.g. https://x:8443/), return it.
// - If not, use the default port for http/https (80/443).
// - If scheme is unknown, return -1.
static inline NSInteger BSGNormalizedPort(NSURL *u) {
    if (u == nil) {
        return -1;
    }

    // If the URL explicitly includes a port, use it
    if (u.port != nil) return u.port.integerValue;

    // Otherwise infer default port from scheme
    NSString *s = u.scheme.lowercaseString ?: @"";
    if ([s isEqualToString:@"https"]) return 443;
    if ([s isEqualToString:@"http"]) return 80;

    // Unknown scheme -> can't reliably infer default port
    return -1;
}

// Compares two URLs to see if they represent the same endpoint
// by matching: scheme + host + port + (normalized) path.
//
// This intentionally ignores query parameters and fragments.
// Example: ".../v1/traces?x=y" still matches ".../v1/traces".
static inline bool BSGURLsMatchSchemeHostPortPath(NSURL *a, NSURL *b) {
    // If either URL is nil, they cannot match
    if (!a || !b) return false;

    // Extract scheme/host safely (use "" if nil so comparisons don't crash)
    NSString *aScheme = a.scheme ?: @"";
    NSString *bScheme = b.scheme ?: @"";
    NSString *aHost = a.host ?: @"";
    NSString *bHost = b.host ?: @"";

    // Scheme comparison: case-insensitive (HTTPS vs https)
    if ([aScheme caseInsensitiveCompare:bScheme] != NSOrderedSame) return false;

    // Host comparison: case-insensitive (domain names are case-insensitive)
    if ([aHost caseInsensitiveCompare:bHost] != NSOrderedSame) return false;

    // Compare normalized ports (explicit ports match defaults properly)
    NSInteger ap = BSGNormalizedPort(a);
    NSInteger bp = BSGNormalizedPort(b);
    if (ap != bp) return false;

    // Normalize paths to avoid trailing-slash mismatches
    NSString *aPath = BSGNormalizePath(a.path);
    NSString *bPath = BSGNormalizePath(b.path);

    // If normalized paths match exactly, consider it a match
    return [aPath isEqualToString:bPath];
}

}
