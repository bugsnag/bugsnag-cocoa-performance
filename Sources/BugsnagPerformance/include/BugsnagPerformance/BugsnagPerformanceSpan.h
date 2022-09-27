//
//  BugsnagPerformanceSpan.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceSpan : NSObject

- (void)end;

- (void)endWithTime:(NSDate *)time NS_SWIFT_NAME(end(time:));

@end

NS_ASSUME_NONNULL_END
