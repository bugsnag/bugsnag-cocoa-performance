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
template<typename T>
static inline T *BSGDynamicCast(__unsafe_unretained id obj) {
    if ([obj isKindOfClass:[T class]]) {
        return obj;
    }
    return nil;
}
}
