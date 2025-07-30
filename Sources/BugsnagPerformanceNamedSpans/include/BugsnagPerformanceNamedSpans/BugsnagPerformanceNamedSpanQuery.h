//
//  BugsnagPerformanceNamedSpanQuery.h
//  BugsnagPerformanceNamedSpans
//
//  Created by Yousif Ahmed on 28/07/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//
#import <BugsnagPerformance/BugsnagPerformanceSpanQuery.h>

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceNamedSpanQuery : BugsnagPerformanceSpanQuery

+ (instancetype)queryWithName:(nonnull NSString *)name;

@end

NS_ASSUME_NONNULL_END
