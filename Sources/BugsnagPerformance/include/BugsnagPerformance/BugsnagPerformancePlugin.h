//
//  BugsnagPerformancePlugin.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/05/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BugsnagPerformancePluginContext;

NS_ASSUME_NONNULL_BEGIN

/**
 * A plugin interface that provides a way to extend the functionality of the performance monitoring
 * library. Plugins are added to the library via the -[BugsnagPerformanceConfiguration addPlugin:]
 * method, and are called when the library is started.
 */
@protocol BugsnagPerformancePlugin <NSObject>

/**
 * Called when the plugin is loaded. This is where you can set up any necessary resources or
 * configurations for the plugin. This is called synchronously as part of
 * +[BugsnagPerformance startWithConfiguration:] to configure any callbacks and hooks that the plugin needs to
 * perform its work.
 *
 * @param context The context in which the plugin is being loaded. The context should not be used again after this method returns.
 * @see +[BugsnagPerformance startWithConfiguration:]
 */
- (void)installWithContext:(BugsnagPerformancePluginContext *)context;

/**
 * Start the plugin. This is called after all plugins have been installed and is where you can
 * start any background tasks or other operations that the plugin needs to perform. This is
 * called asynchronously after [BugsnagPerformance.start] to allow the plugin to perform
 * any necessary work without blocking the main thread.
 */
- (void)start;

@end

NS_ASSUME_NONNULL_END
