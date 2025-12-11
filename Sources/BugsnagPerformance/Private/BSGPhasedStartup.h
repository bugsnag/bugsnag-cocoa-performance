//
//  BSGPhasedStartup.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 11/12/2025.
//

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import "EarlyConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BSGConfigurable

/**
 * Perform user configuration. This is called as a consequence of the user calling [BugsnagPerformance start],
 * and performs configuration according to what the user provided.
 */
- (void)configure:(BugsnagPerformanceConfiguration *)config;

@end

@protocol BSGEarlyPhaseConfigurable <NSObject>

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

@end

@protocol BSGPreStartSetupable

/**
 * Perform pre-start setup. Like earlySetup(), this step gives each component an
 * opportunity to perform any required setup in response to the configuration.
 *
 * It's split into a separate step so that any cross-component calls will always be
 * made to an already-configured object.
 */
- (void)preStartSetup;

@end

@protocol BSGStartable

/**
 * Start this fully configured and set up component.
 *
 * This step is for actions that aren't part of the setup, but rather for "running" the object.
 * This is typically for things such as starting threads and queues, patching into system callbacks, etc.
 */
- (void)start;

@end

@protocol BSGPhasedStartup <BSGConfigurable, BSGEarlyPhaseConfigurable, BSGPreStartSetupable, BSGStartable>
@end

NS_ASSUME_NONNULL_END
