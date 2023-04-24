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

@end

@interface BugsnagPerformanceConfiguration ()

/**
 *  Whether reports should be sent, based on release stage options
 *
 *  @return YES if reports should be sent based on this configuration
 */
- (BOOL)shouldSendReports;

@property(nonatomic,readwrite) BSGInternalConfiguration *internal;

@end

NS_ASSUME_NONNULL_END
