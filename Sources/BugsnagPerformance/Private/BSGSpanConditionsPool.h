//
//  BSGSpanConditionsPool.h
//  BugsnagPerformance
//
//  Created by Robert B on 13/02/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanCondition.h>

NS_ASSUME_NONNULL_BEGIN

@interface BSGSpanConditionsPool: NSObject

@property (nonatomic, readonly) NSArray *conditions;

+ (instancetype)pool;

- (void)add:(BugsnagPerformanceSpanCondition *)condition;
- (void)clear;

@end

NS_ASSUME_NONNULL_END
