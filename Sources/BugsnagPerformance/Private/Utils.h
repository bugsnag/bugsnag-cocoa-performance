//
//  Utils.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 08/11/2022.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

#define BSG_LOGLEVEL_NONE 0
#define BSG_LOGLEVEL_ERR 10
#define BSG_LOGLEVEL_WARN 20
#define BSG_LOGLEVEL_INFO 30
#define BSG_LOGLEVEL_DEBUG 40

#ifndef BSG_LOG_LEVEL
#define BSG_LOG_LEVEL BSG_LOGLEVEL_INFO
#endif

#define BSG_LOG_PREFIX "[BugsnagPerformance]"

#if BSG_LOG_LEVEL >= BSG_LOGLEVEL_ERR
#define BSGLogError(...)    NSLog(@ BSG_LOG_PREFIX " [ERROR] " __VA_ARGS__)
#else
#define BSGLogError(format, ...)
#endif

#if BSG_LOG_LEVEL >= BSG_LOGLEVEL_WARN
#define BSGLogWarning(...)  NSLog(@ BSG_LOG_PREFIX " [WARN] " __VA_ARGS__)
#else
#define BSGLogWarning(format, ...)
#endif

#if BSG_LOG_LEVEL >= BSG_LOGLEVEL_INFO
#define BSGLogInfo(...)     NSLog(@ BSG_LOG_PREFIX " [INFO] " __VA_ARGS__)
#else
#define BSGLogInfo(format, ...)
#endif

#if BSG_LOG_LEVEL >= BSG_LOGLEVEL_DEBUG
#define BSGLogDebug(...)    NSLog(@ BSG_LOG_PREFIX " [DEBUG] " __VA_ARGS__)
#else
#define BSGLogDebug(format, ...)
#endif

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

}
