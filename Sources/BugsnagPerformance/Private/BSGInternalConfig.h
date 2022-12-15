//
//  BSGInternalConfig.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 14.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#ifndef BSGInternalConfig_h
#define BSGInternalConfig_h

#include <stdint.h>
#include <dispatch/time.h>

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#else
typedef double NSTimeInterval;
#endif

// Exposed internally for testing and CI

extern uint64_t bsgp_autoTriggerExportOnBatchSize;

extern dispatch_time_t bsgp_autoTriggerExportOnTimeDuration;

extern NSTimeInterval bsgp_performWorkInterval;

#endif /* BSGInternalConfig_h */
