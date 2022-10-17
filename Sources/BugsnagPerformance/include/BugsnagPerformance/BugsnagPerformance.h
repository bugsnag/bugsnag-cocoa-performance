//
//  BugsnagPerformance.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import <BugsnagPerformance/BugsnagPerformanceSpan.h>
#import <BugsnagPerformance/BugsnagPerformanceViewType.h>

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformance : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (void)start;

+ (void)startWithConfiguration:(BugsnagPerformanceConfiguration *)configuration NS_SWIFT_NAME(start(configuration:));

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name NS_SWIFT_NAME(startSpan(name:));

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name startTime:(NSDate *)startTime NS_SWIFT_NAME(startSpan(name:startTime:));

@end

@interface BugsnagPerformance (/* Manual view load spans */)

+ (BugsnagPerformanceSpan *)startViewLoadSpanWithName:(NSString *)name
                                             viewType:(BugsnagPerformanceViewType)viewType
  NS_SWIFT_NAME(startViewLoadSpan(name:viewType:));

+ (BugsnagPerformanceSpan *)startViewLoadSpanWithName:(NSString *)name
                                             viewType:(BugsnagPerformanceViewType)viewType
                                            startTime:(NSDate *)startTime
  NS_SWIFT_NAME(startViewLoadSpan(name:viewType:startTime:));

@end

@interface BugsnagPerformance (/* Manual network spans */)

+ (void)reportNetworkRequestSpanWithTask:(NSURLSessionTask *)task
                                 metrics:(NSURLSessionTaskMetrics *)metrics
  NS_SWIFT_NAME(reportNetworkRequestSpan(task:metrics:));

@end

NS_ASSUME_NONNULL_END
