//
//  BugsnagPerformance.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import <BugsnagPerformance/BugsnagPerformanceErrors.h>
#import <BugsnagPerformance/BugsnagPerformanceSpan.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanOptions.h>
#import <BugsnagPerformance/BugsnagPerformanceViewType.h>
#import <BugsnagPerformance/BugsnagPerformanceNetworkRequestInfo.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT
@interface BugsnagPerformance : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (void)start;

+ (void)startWithApiKey:(NSString *)apiKey;

+ (void)startWithConfiguration:(BugsnagPerformanceConfiguration *)configuration NS_SWIFT_NAME(start(configuration:));

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name NS_SWIFT_NAME(startSpan(name:));

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name options:(BugsnagPerformanceSpanOptions *)options NS_SWIFT_NAME(startSpan(name:options:));

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
                                             parentContext:(BugsnagPerformanceSpan *)parentContext
  NS_SWIFT_NAME(startViewLoadPhaseSpan(name:phase:parentContext:));

@end

@interface BugsnagPerformance (/* Manual network spans */)

+ (void)reportNetworkRequestSpanWithTask:(NSURLSessionTask *)task
                                 metrics:(NSURLSessionTaskMetrics *)metrics
  NS_SWIFT_NAME(reportNetworkRequestSpan(task:metrics:));

@end

NS_ASSUME_NONNULL_END
