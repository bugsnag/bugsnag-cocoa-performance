//
//  PhasedStartup.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 12.04.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import "EarlyConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

/* Phased library startup protocols and interfaces.
 *
 * Library startup occurs in four phases, where each component is called in-order using
 * the API of the current phase.
 *
 * The APIs for each phase are:
 * - earlyConfigure(): Called as early as possible upon library init, using Info.plist as a source.
 * - earlySetup(): Called immediately after earlyConfigure().
 * - configure(): Called via [BugsnagPerformance startWithConfiguration:]
 * - start(): Called immediately after configure().
 */
class PhasedStartup {
public:
    virtual void earlyConfigure(BSGEarlyConfiguration *config) noexcept = 0;
    virtual void earlySetup() noexcept = 0;
    virtual void configure(BugsnagPerformanceConfiguration *config) noexcept = 0;
    virtual void preStartSetup() noexcept = 0;
    virtual void start() noexcept = 0;
    virtual ~PhasedStartup() {}
};

}

@protocol BSGPhasedStartup

- (void)earlyConfigure:(BSGEarlyConfiguration *)config;

- (void)earlySetup;

- (void)configure:(BugsnagPerformanceConfiguration *)config;

- (void)preStartSetup;

- (void)start;

@end

NS_ASSUME_NONNULL_END
