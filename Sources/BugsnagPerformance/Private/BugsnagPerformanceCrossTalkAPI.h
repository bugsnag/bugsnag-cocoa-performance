//
//  BugsnagPerformanceCrossTalkAPI.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.05.24.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpanStackingHandler.h"
#import "BugsnagPerformanceImpl.h"

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceCrossTalkAPI : NSObject

#pragma mark Mandatory Methods

+ (instancetype) sharedInstance;

#pragma mark Configuration and Internal Functions

@property(nonatomic) std::shared_ptr<SpanStackingHandler> spanStackingHandler;
@property(nonatomic) BugsnagPerformanceConfiguration *configuration;

@end

NS_ASSUME_NONNULL_END
