//
//  BSGInternalConfig.c
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 14.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#include "BSGInternalConfig.h"

uint64_t bsgp_autoTriggerExportOnBatchSize = 100;

dispatch_time_t bsgp_autoTriggerExportOnTimeDuration = 30 * NSEC_PER_SEC;

NSTimeInterval bsgp_performWorkInterval = 30;
