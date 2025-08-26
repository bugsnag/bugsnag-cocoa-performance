//
//  BugsnagPerformance.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import <BugsnagPerformance/BugsnagPerformanceErrors.h>
#import <BugsnagPerformance/BugsnagPerformanceSpan.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanContext.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanOptions.h>
#import <BugsnagPerformance/BugsnagPerformanceViewType.h>
#import <BugsnagPerformance/BugsnagPerformanceNetworkRequestInfo.h>
#import <BugsnagPerformance/BugsnagPerformanceTrackedViewContainer.h>
#import <BugsnagPerformance/BugsnagPerformanceRemoteSpanContext.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanControl.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanControlProvider.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanQuery.h>
#import <BugsnagPerformance/BugsnagPerformancePriority.h>
#import <BugsnagPerformance/BugsnagPerformancePlugin.h>
#import <BugsnagPerformance/BugsnagPerformancePluginContext.h>
#import <BugsnagPerformance/BugsnagPerformanceLoadingIndicatorView.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT
@interface BugsnagPerformance : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (void)start;

+ (void)startWithApiKey:(NSString *)apiKey;

+ (void)startWithConfiguration:(BugsnagPerformanceConfiguration *)configuration NS_SWIFT_NAME(start(configuration:));

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name NS_SWIFT_NAME(startSpan(name:));

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name options:(BugsnagPerformanceSpanOptions *)options NS_SWIFT_NAME(startSpan(name:options:));

+ (BugsnagPerformanceSpanContext *)currentContext;

@end

@interface BugsnagPerformance (/* Manual view load spans */)

+ (BugsnagPerformanceSpan *)startViewLoadSpanWithName:(NSString *)name
                                             viewType:(BugsnagPerformanceViewType)viewType
  NS_SWIFT_NAME(startViewLoadSpan(name:viewType:));

+ (BugsnagPerformanceSpan *)startViewLoadSpanWithName:(NSString *)name
                                             viewType:(BugsnagPerformanceViewType)viewType
                                              options:(BugsnagPerformanceSpanOptions *)options
  NS_SWIFT_NAME(startViewLoadSpan(name:viewType:options:));

+ (void)startViewLoadSpanWithController:(UIViewController *)controller
                                options:(BugsnagPerformanceSpanOptions *)options
  NS_SWIFT_NAME(startViewLoadSpan(controller:options:));

+ (void)endViewLoadSpanWithController:(UIViewController *)controller
                              endTime:(NSDate *)endTime
  NS_SWIFT_NAME(endViewLoadSpan(controller:endTime:));

+ (BugsnagPerformanceSpan *)startViewLoadPhaseSpanWithName:(NSString *)name
                                                     phase:(NSString *)phase
                                             parentContext:(BugsnagPerformanceSpanContext *)parentContext
  NS_SWIFT_NAME(startViewLoadPhaseSpan(name:phase:parentContext:));

@end

@interface BugsnagPerformance (/* Manual network spans */)

+ (void)reportNetworkRequestSpanWithTask:(NSURLSessionTask *)task
                                 metrics:(NSURLSessionTaskMetrics *)metrics
  NS_SWIFT_NAME(reportNetworkRequestSpan(task:metrics:));

@end

@interface BugsnagPerformance (/* Span controls */)

/**
 * Attempt to retrieve the span controls for a given [BugsnagPerformanceSpanQuery]. This is used to access
 * specialised behaviours for specific span types.
 *
 * @param query the span query to retrieve controls for
 * @return the span controls for the given query, or nil if none exists or the query cannot
 *      be fulfilled
 */
+ (__nullable id<BugsnagPerformanceSpanControl>)getSpanControlsWithQuery:(BugsnagPerformanceSpanQuery *)query;

@end

NS_ASSUME_NONNULL_END
