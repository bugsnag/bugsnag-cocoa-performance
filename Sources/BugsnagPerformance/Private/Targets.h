//
//  Targets.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 20.03.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

// Targets based on what technologis they use.
// We can't depend on includes being present or not because catalyst target will have a crippled appkit include.

#define BSG_TARGET_UIKIT (TARGET_OS_IOS || TARGET_OS_MACCATALYST || TARGET_OS_TV)

#define BSG_TARGET_WATCHKIT (TARGET_OS_WATCH)

#define BSG_TARGET_APPKIT (TARGET_OS_OSX)
