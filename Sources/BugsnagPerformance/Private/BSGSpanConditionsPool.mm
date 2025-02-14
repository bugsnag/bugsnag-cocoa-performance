//
//  BSGSpanConditionsPool.m
//  BugsnagPerformance-iOS
//
//  Created by Robert B on 13/02/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "BSGSpanConditionsPool.h"
#import <BugsnagPerformance/BugsnagPerformanceSpanCondition.h>

@interface BSGSpanConditionsPool ()

@property (nonatomic, strong) NSMutableArray<BugsnagPerformanceSpanCondition *> *conditions_;

@end

@implementation BSGSpanConditionsPool

+ (instancetype)pool {
    return [[self alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _conditions_ = [NSMutableArray new];
    }
    return self;
}

- (void)add:(BugsnagPerformanceSpanCondition *)condition {
    @synchronized (self) {
        if ([condition upgrade] != nil) {
            [self.conditions_ addObject:condition];
        }
    }
}

- (void)forEach:(void (^)(BugsnagPerformanceSpanCondition *))block {
    @synchronized (self) {
        for (BugsnagPerformanceSpanCondition *condition in self.conditions_) {
            block(condition);
        }
    }
}

- (NSArray *)conditions {
    @synchronized (self) {
        return [self.conditions_ copy];
    }
}

- (void)clear {
    @synchronized (self) {
        for (BugsnagPerformanceSpanCondition *condition in self.conditions_) {
            if (condition.isActive) {
                [condition cancel];
            }
        }
        self.conditions_ = [NSMutableArray new];
    }
}

- (void)dealloc
{
    for (BugsnagPerformanceSpanCondition *condition in self.conditions_) {
        if (condition.isActive) {
            [condition cancel];
        }
    }
}

@end
