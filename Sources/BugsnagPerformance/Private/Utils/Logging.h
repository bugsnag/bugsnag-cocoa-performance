//
//  Logging.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 05/06/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#define BSG_LOGLEVEL_NONE 0
#define BSG_LOGLEVEL_ERR 10
#define BSG_LOGLEVEL_WARN 20
#define BSG_LOGLEVEL_INFO 30
#define BSG_LOGLEVEL_DEBUG 40
#define BSG_LOGLEVEL_TRACE 50

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

#if BSG_LOG_LEVEL >= BSG_LOGLEVEL_TRACE
#define BSGLogTrace(...)    NSLog(@ BSG_LOG_PREFIX " [TRACE] " __VA_ARGS__)
#else
#define BSGLogTrace(format, ...)
#endif
