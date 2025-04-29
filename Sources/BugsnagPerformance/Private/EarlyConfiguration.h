//
//  EarlyConfiguration.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 02.05.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The early confguration happens duing the library early init phase (before main is called), and thus cannot be done
 * using a configuration object passed in by the user (because control hasn't been passed to user code yet).
 * Instead, we get the early configuration from the app's Info.plist file and environment variables.
 */
@interface BSGEarlyConfiguration : NSObject

/**
 * Configure from Info.plist
 * This constructor extracts a dictionary from the contents of Info.plist and calls the other constructor.
 */
- (instancetype) init;

/**
 * Configure from an Info.plist style dictionary.
 */
- (instancetype) initWithBundleDictionary:(NSDictionary *)dict;

@property(nonatomic, readonly) BOOL enableSwizzling;
@property(nonatomic, readonly) BOOL swizzleViewLoadPreMain;
@property(nonatomic, readwrite) BOOL appWasLaunchedPreWarmed;

/*
 The following options are temporarily added for testing purposes only
 Disabling individual instrumentation of individual callbacks can lead to unexpected behaviour
 */
@property(nonatomic, readonly) BOOL instrumentLoadView;
@property(nonatomic, readonly) BOOL instrumentViewDidLoad;
@property(nonatomic, readonly) BOOL instrumentViewWillAppear;
@property(nonatomic, readonly) BOOL instrumentViewDidAppear;
@property(nonatomic, readonly) BOOL instrumentViewWillLayoutSubviews;
@property(nonatomic, readonly) BOOL instrumentViewDidLayoutSubviews;
@property(nonatomic, readonly) BOOL instrumentNetwork;

@end

NS_ASSUME_NONNULL_END
