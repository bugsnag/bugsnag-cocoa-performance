//
//  BugsnagPerformancePluginContext.m
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/05/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "../Private/BugsnagPerformancePluginContext+Private.h"
#import "../Private/BugsnagPerformanceSpanControlProvider+Private.h"

@interface BugsnagPerformancePluginContext ()
@property (nonatomic, strong) BugsnagPerformanceConfiguration *configuration_;
@property (nonatomic, copy) AddSpanControlProviderBlock addSpanControlProviderBlock;
@property (nonatomic, copy) AddStartSpanCallbackBlock addSpanStartBlock;
@property (nonatomic, copy) AddEndSpanCallbackBlock addSpanEndBlock;
@end

@implementation BugsnagPerformancePluginContext

- (instancetype)initWithConfiguration:(BugsnagPerformanceConfiguration *)configuration
          addSpanControlProviderBlock:(AddSpanControlProviderBlock)addSpanControlProviderBlock
                    addSpanStartBlock:(AddStartSpanCallbackBlock)addSpanStartBlock
                      addSpanEndBlock:(AddEndSpanCallbackBlock)addSpanEndBlock
{
    self = [super init];
    if (self) {
        _configuration_ = configuration;
        _addSpanControlProviderBlock = addSpanControlProviderBlock;
        _addSpanStartBlock = addSpanStartBlock;
        _addSpanEndBlock = addSpanEndBlock;
    }
    return self;
}

- (BugsnagPerformanceConfiguration *)configuration {
    return self.configuration_;
}

- (void)addSpanControlProvider:(id<BugsnagPerformanceSpanControlProvider>)provider {
    [self addSpanControlProvider:provider priority:BugsnagPerformancePriorityMedium];
}

- (void)addSpanControlProvider:(id<BugsnagPerformanceSpanControlProvider>)provider priority:(BugsnagPerformancePriority)priority {
    @synchronized (self) {
        if (self.addSpanControlProviderBlock) {
            self.addSpanControlProviderBlock(provider, priority);
        }
    }
}

- (void)addOnSpanStartCallback:(BugsnagPerformanceSpanStartCallback)callback {
    [self addOnSpanStartCallback:callback priority:BugsnagPerformancePriorityMedium];
}

- (void)addOnSpanStartCallback:(BugsnagPerformanceSpanStartCallback)callback priority:(BugsnagPerformancePriority)priority {
    @synchronized (self) {
        if (self.addSpanStartBlock) {
            self.addSpanStartBlock(callback, priority);
        }
    }
}

- (void)addOnSpanEndCallback:(BugsnagPerformanceSpanEndCallback)callback {
    [self addOnSpanEndCallback:callback priority:BugsnagPerformancePriorityMedium];
}

- (void)addOnSpanEndCallback:(BugsnagPerformanceSpanEndCallback)callback priority:(BugsnagPerformancePriority)priority {
    @synchronized (self) {
        if (self.addSpanEndBlock) {
            self.addSpanEndBlock(callback, priority);
        }
    }
}

@end
