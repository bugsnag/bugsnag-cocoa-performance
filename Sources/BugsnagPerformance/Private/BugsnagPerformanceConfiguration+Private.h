//
//  BugsnagPerformanceConfiguration+Private.h
//  BugsnagPerformance
//
//  Created by Robert B on 16/03/2023.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>

NS_ASSUME_NONNULL_BEGIN

@interface BSGInternalConfiguration: NSObject

@property(nonatomic,readwrite) bool clearPersistenceOnStart;

@property(nonatomic,readwrite) uint64_t autoTriggerExportOnBatchSize;

@property(nonatomic,readwrite) NSTimeInterval performWorkInterval;

@property(nonatomic,readwrite) NSTimeInterval maxRetryAge;

@property(nonatomic,readwrite) CFTimeInterval probabilityValueExpiresAfterSeconds;
@property(nonatomic,readwrite) CFTimeInterval probabilityRequestsPauseForSeconds;

@property (nonatomic) double initialSamplingProbability;

@property (nonatomic) uint64_t maxPackageContentLength;

/**
 * Delay between sending the initial P value request and doing the first cycle of work
 * (to ensure that the initial P value request span is the first one received during an e2e test)
 */
@property(nonatomic,readwrite) NSTimeInterval initialRecurringWorkDelay;

@end

@interface BugsnagPerformanceConfiguration ()

+ (instancetype)loadConfigWithInfoDictionary:(NSDictionary * _Nullable)infoDictionary;

/**
 *  Whether reports should be sent, based on release stage options
 *
 *  @return YES if reports should be sent based on this configuration
 */
- (BOOL)shouldSendReports;

@property(nonatomic,readwrite) BSGInternalConfiguration *internal;

@end

NS_ASSUME_NONNULL_END
