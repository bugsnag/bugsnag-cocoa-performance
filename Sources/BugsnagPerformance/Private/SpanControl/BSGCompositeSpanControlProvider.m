//
//  BSGCompositeSpanControlProvider.m
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/05/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "BSGCompositeSpanControlProvider.h"

@interface BSGCompositeSpanControlProvider ()

@property (nonatomic,
           strong) BSGPrioritizedStore<id<BugsnagPerformanceSpanControlProvider>> *providers;

@end

@implementation BSGCompositeSpanControlProvider

- (instancetype)init
{
    self = [super init];
    if (self) {
        _providers = [BSGPrioritizedStore new];
    }
    return self;
}

- (void)batchAddProviders:(BSGCompositeSpanControlProviderBatchBlock)batchBlock {
    [self.providers batchAddObjects:batchBlock];
}

- (id<BugsnagPerformanceSpanControl> _Nullable)getSpanControlsWithQuery:(nonnull BugsnagPerformanceSpanQuery *)query {
    for (id<BugsnagPerformanceSpanControlProvider> provider in self.providers.objects) {
        id<BugsnagPerformanceSpanControl> spanControl = [provider getSpanControlsWithQuery:query];
        if ([spanControl isKindOfClass:query.resultType]) {
            return spanControl;
        }
    }
    return nil;
}

@end
