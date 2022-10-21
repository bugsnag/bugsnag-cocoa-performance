//
//  BugsnagPerformanceSpan.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT
@interface BugsnagPerformanceSpan : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (void)end;

- (void)endWithEndTime:(NSDate *)endTime NS_SWIFT_NAME(end(endTime:));

@end

NS_ASSUME_NONNULL_END
