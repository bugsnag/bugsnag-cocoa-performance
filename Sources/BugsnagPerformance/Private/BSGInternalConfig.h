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
#include <dispatch/dispatch.h>
#include <CoreFoundation/CFDate.h>

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#else
typedef double NSTimeInterval;
#endif

// Exposed internally for testing and CI

extern uint64_t bsgp_autoTriggerExportOnBatchSize;

extern NSTimeInterval bsgp_performWorkInterval;

extern NSTimeInterval bsgp_maxRetryAge;

extern CFTimeInterval bsgp_probabilityValueExpiresAfterSeconds;
extern CFTimeInterval bsgp_probabilityRequestsPauseForSeconds;

#endif /* BSGInternalConfig_h */
