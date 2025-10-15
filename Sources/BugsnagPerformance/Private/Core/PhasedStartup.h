//
//  PhasedStartup.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 12.04.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import "Configuration/EarlyConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

/* Phased library startup protocols and interfaces.
 *
 * Library startup occurs in multiple phases, where each component is called in-order using
 * the API of the currently running phase.
 *
 * The APIs for each phase are:
 * - earlyConfigure(): Called as early as possible upon library init, using Info.plist as a source.
 * - earlySetup(): Called immediately after earlyConfigure().
 * - configure(): Called via [BugsnagPerformance startWithConfiguration:]
 * - preStartSetup(): Called immediately after configure().
 * - start(): Called immediately after preStartSetup().
 */
class PhasedStartup {
public:
    /**
     * Perform "early" configuration. This is called before main(), using configuration data
     * pulled from the environment (Info.plist).
     *
     * It's called automatically by BugsnagPerformanceLibrary, and does not require any user runtime actions.
     */
    virtual void earlyConfigure(BSGEarlyConfiguration *config) noexcept = 0;

    /**
     * Perform "early" setup. This is called before main(), and gives each component an
     * opportunity to perform any setup in response to the early configuration.
     *
     * It's split into a separate step so that any cross-component calls will always be
     * made to an already-configured object.
     */
    virtual void earlySetup() noexcept = 0;

    /**
     * Perform user configuration. This is called as a consequence of the user calling [BugsnagPerformance start],
     * and performs configuration according to what the user provided.
     */
    virtual void configure(BugsnagPerformanceConfiguration *config) noexcept = 0;

    /**
     * Perform pre-start setup. Like earlySetup(), this step gives each component an
     * opportunity to perform any required setup in response to the configuration.
     *
     * It's split into a separate step so that any cross-component calls will always be
     * made to an already-configured object.
     */
    virtual void preStartSetup() noexcept = 0;

    /**
     * Start this fully configured and set up component.
     *
     * This step is for actions that aren't part of the setup, but rather for "running" the object.
     * This is typically for things such as starting threads and queues, patching into system callbacks, etc.
     */
    virtual void start() noexcept = 0;

    virtual ~PhasedStartup() {}
};

}

@protocol BSGPhasedStartup

/**
 * Perform "early" configuration. This is called before main(), using configuration data
 * pulled from the environment (Info.plist).
 *
 * It's called automatically by BugsnagPerformanceLibrary, and does not require any user runtime actions.
 */
- (void)earlyConfigure:(BSGEarlyConfiguration *)config;

/**
 * Perform "early" setup. This is called before main(), and gives each component an
 * opportunity to perform any setup in response to the early configuration.
 *
 * It's split into a separate step so that any cross-component calls will always be
 * made to an already-configured object.
 */
- (void)earlySetup;

/**
 * Perform user configuration. This is called as a consequence of the user calling [BugsnagPerformance start],
 * and performs configuration according to what the user provided.
 */
- (void)configure:(BugsnagPerformanceConfiguration *)config;

/**
 * Perform pre-start setup. Like earlySetup(), this step gives each component an
 * opportunity to perform any required setup in response to the configuration.
 *
 * It's split into a separate step so that any cross-component calls will always be
 * made to an already-configured object.
 */
- (void)preStartSetup;

/**
 * Start this fully configured and set up component.
 *
 * This step is for actions that aren't part of the setup, but rather for "running" the object.
 * This is typically for things such as starting threads and queues, patching into system callbacks, etc.
 */
- (void)start;

@end

NS_ASSUME_NONNULL_END
