//
//  BugsnagPerformanceNamedSpanQuery.m
//  BugsnagPerformance
//
//  Created by Yousif Ahmed on 28/07/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//
#import <BugsnagPerformanceNamedSpans/BugsnagPerformanceNamedSpanQuery.h>
#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

static NSString * const spanNameAttributeKey = @"name";

@implementation BugsnagPerformanceNamedSpanQuery

+ (instancetype)queryWithName:(NSString *)spanName {
    NSDictionary *attributes = @{spanNameAttributeKey: spanName};
    return [self queryWithResultType:[BugsnagPerformanceSpan class] attributes:attributes];
}

@end
