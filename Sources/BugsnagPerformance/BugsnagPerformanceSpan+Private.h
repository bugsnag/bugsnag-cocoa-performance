//
//  BugsnagPerformanceSpan.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

#import "Span.h"

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceSpan ()

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithSpan:(Span *)span NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
