//
//  BugsnagPerformancePluginContext.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/05/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BugsnagPerformance/BugsnagPerformancePriority.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanControlProvider.h>
#import <BugsnagPerformance/BugsnagPerformanceSpan.h>
#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT
@interface BugsnagPerformancePluginContext : NSObject

/**
 * The user provided configuration for the performance monitoring library. Changes made by
 * the plugin to this configuration may be *ignored* by the library, so plugins should not
 * modify this configuration directly (instead making any changes via the [BugsnagPerformancePluginContext] methods).
 */
@property (nonatomic, readonly) BugsnagPerformanceConfiguration *cofiguration;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Add a [BugsnagPerformanceSpanControlProvider] to the list of providers that can be queried via
 * +[BugsnagPerformance getSpanControlsWithQuery:]. This is a convenience method that is the same as calling
 * -[BugsnagPerformancePluginContext addSpanControlProvider:priority:] with the default priority of [BugsnagPerformancePriorityMedium].
 *
 * @param provider Span controls provider. Adding the same provider multiple times will not take effect
 * @see +[BugsnagPerformance getSpanControlsWithQuery:]
 */
- (void)addSpanControlProvider:(id<BugsnagPerformanceSpanControlProvider>)provider;

/**
 * Add a [BugsnagPerformanceSpanControlProvider] to the list of providers that can be queried via
 * +[BugsnagPerformance getSpanControlsWithQuery:].
 *
 * @param provider Span controls provider. Adding the same provider multiple times will not take effect
 * @param priority The priority of the provider determines the order in which it will be queried, with higher priorities being queried first.
 * @see +[BugsnagPerformance getSpanControlsWithQuery:]
 */
- (void)addSpanControlProvider:(id<BugsnagPerformanceSpanControlProvider>)provider priority:(BugsnagPerformancePriority)priority;

/**
 * Add a [BugsnagPerformanceSpanStartCallback] to the list of callbacks that will be called when a span is
 * started. This is a convenience method that is the same as calling
 * -[BugsnagPerformancePluginContext addOnSpanStartCallback:priority:] with the default priority of [BugsnagPerformancePriorityMedium].
 *
 * @param onSpanEndCallback Callback to be called on span start. Adding the same callback multiple times will not take effect
 * @see -[BugsnagPerformancePluginContext addOnSpanStartCallback:priority:]
 */
- (void)addOnSpanStartCallback:(BugsnagPerformanceSpanStartCallback)callback;

/**
 * Add a [BugsnagPerformanceSpanStartCallback] to the list of callbacks that will be called when a span is
 * started. The priority of the callback determines the order in which it will be called,
 * with lower numbers being called first. The default priority is [BugsnagPerformancePriorityMedium] (which
 * is also the priority of the [BugsnagPerformanceSpanStartCallback] added in
 * -[BugsnagPerformanceConfiguration addOnSpanStartCallback:]).
 *
 * @param onSpanEndCallback Callback to be called on span start. Adding the same callback multiple times will not take effect
 * @param priority The priority of the callback determines the order in which it will be called, with higher priorities being called first.
 * @see -[BugsnagPerformanceConfiguration addOnSpanStartCallback:]
 */
- (void)addOnSpanStartCallback:(BugsnagPerformanceSpanStartCallback)callback priority:(BugsnagPerformancePriority)priority;

/**
 * Add a [BugsnagPerformanceSpanEndCallback] to the list of callbacks that will be called when a span is
 * ended. This is a convenience method that is the same as calling
 * -[BugsnagPerformancePluginContext addOnSpanEndCallback:priority:] with the default priority of [BugsnagPerformancePriorityMedium].
 *
 * @param onSpanEndCallback Callback to be called on span end. Adding the same callback multiple times will not take effect
 * @see -[BugsnagPerformancePluginContext addOnSpanEndCallback:priority:]
 */
- (void)addOnSpanEndCallback:(BugsnagPerformanceSpanEndCallback)callback;

/**
 * Add a [BugsnagPerformanceSpanEndCallback] to the list of callbacks that will be called when a span is
 * ended. The priority of the callback determines the order in which it will be called,
 * with lower numbers being called first. The default priority is [BugsnagPerformancePriorityMedium] (which
 * is also the priority of the [BugsnagPerformanceSpanEndCallback] added in
 * -[BugsnagPerformanceConfiguration addOnSpanEndCallback:]).
 *
 * @param onSpanEndCallback Callback to be called on span end. Adding the same callback multiple times will not take effect
 * @param priority The priority of the callback determines the order in which it will be called, with higher priorities being called first.
 * @see -[BugsnagPerformanceConfiguration addOnSpanEndCallback:]
 */
- (void)addOnSpanEndCallback:(BugsnagPerformanceSpanEndCallback)callback priority:(BugsnagPerformancePriority)priority;

@end

NS_ASSUME_NONNULL_END
