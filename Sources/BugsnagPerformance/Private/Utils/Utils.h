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


}
