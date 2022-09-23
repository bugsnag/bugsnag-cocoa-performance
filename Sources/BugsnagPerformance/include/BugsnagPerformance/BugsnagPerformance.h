//
//  BugsnagPerformance.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformance : NSObject

+ (void)startWithConfiguration:(BugsnagPerformanceConfiguration *)configuration NS_SWIFT_NAME(start(configuration:));

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name NS_SWIFT_NAME(startSpan(name:));

+ (BugsnagPerformanceSpan *)startSpanWithName:(NSString *)name startTime:(NSDate *)startTime NS_SWIFT_NAME(startSpan(name:startTime:));

@end

NS_ASSUME_NONNULL_END
