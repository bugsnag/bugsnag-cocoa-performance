//
//  BSGPluginManager.m
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 05/06/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "BSGPluginManager.h"
#import "../BugsnagPerformancePluginContext+Private.h"
#import "../../Utils/Logging.h"
#import "../../Core/Configuration/BugsnagPerformanceConfiguration+Private.h"

@interface BSGPluginManager ()

@property (nonatomic, strong) BugsnagPerformanceConfiguration *configuration;
@property (nonatomic, strong) BSGCompositeSpanControlProvider *compositeProvider;
@property (nonatomic, strong) BSGPrioritizedStore<BugsnagPerformanceSpanStartCallback> *onSpanStartCallbacks;
@property (nonatomic, strong) BSGPrioritizedStore<BugsnagPerformanceSpanEndCallback> *onSpanEndCallbacks;
@property (nonatomic, strong) NSMutableArray<id<BugsnagPerformancePlugin>> *installedPlugins;

@end

@implementation BSGPluginManager

- (instancetype)initWithSpanControlProvider:(BSGCompositeSpanControlProvider *)compositeProvider
{
    self = [super init];
    if (self) {
        _compositeProvider = compositeProvider;
        _onSpanStartCallbacks = onSpanStartCallbacks;
        _onSpanEndCallbacks = onSpanEndCallbacks;
        _installedPlugins = [NSMutableArray array];
    }
    return self;
}

- (void)installPlugins:(NSArray<id<BugsnagPerformancePlugin>> *)plugins {
    for (id<BugsnagPerformancePlugin> plugin in plugins) {
        @try {
            [self.compositeProvider batchAddProviders:^(AddSpanControlProviderBlock compositeProviderAddBlock) {
                [self.onSpanStartCallbacks batchAddObjects:^(BSGPrioritizedStoreAddBlock onSpanStartCallbacksAddBlock) {
                    [self.onSpanEndCallbacks batchAddObjects:^(BSGPrioritizedStoreAddBlock onSpanEndCallbacksAddBlock) {
                        BugsnagPerformancePluginContext *context = [[BugsnagPerformancePluginContext alloc] initWithConfiguration:self.configuration
                                                                                                      addSpanControlProviderBlock:compositeProviderAddBlock
                                                                                                                addSpanStartBlock:onSpanStartCallbacksAddBlock
                                                                                                                  addSpanEndBlock:onSpanEndCallbacksAddBlock];
                        [plugin installWithContext:context];
                    }];
                }];
            }];
            [self.installedPlugins addObject:plugin];
        } @catch(NSException *e) {
            BSGLogError(@"BSGPluginManager::installPlugins: plugin install threw exception: %@",
                        e);
        }
    }
}

- (void)startPlugins {
    for (id<BugsnagPerformancePlugin> plugin in self.installedPlugins) {
        @try {
            [plugin start];
        } @catch(NSException *e) {
            BSGLogError(@"BSGPluginManager::startPlugins: plugin start threw exception: %@", e);
        }
    }
}

#pragma mark BSGPhasedStartup

- (void)earlyConfigure:(BSGEarlyConfiguration *)config {
}

- (void)earlySetup {
}

- (void)configure:(BugsnagPerformanceConfiguration *)config {
    self.configuration = config;
    for(BugsnagPerformanceSpanStartCallback callback in config.onSpanStartCallbacks) {
        [self.onSpanStartCallbacks addObject:callback priority:BugsnagPerformancePriorityMedium];
    }
    for(BugsnagPerformanceSpanEndCallback callback in config.onSpanEndCallbacks) {
        [self.onSpanEndCallbacks addObject:callback priority:BugsnagPerformancePriorityMedium];
    }
}

- (void)preStartSetup {

}

- (void) start {
}

@end
