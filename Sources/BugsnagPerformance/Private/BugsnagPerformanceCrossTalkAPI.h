//
//  BugsnagPerformanceCrossTalkAPI.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 10.05.24.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpanStackingHandler.h"
#import "PhasedStartup.h"
#import "Tracer.h"

#define BUGSNAG_PERFORMANCE_CROSSTALK_PRESENT 1

NS_ASSUME_NONNULL_BEGIN

@interface BugsnagPerformanceCrossTalkAPI : NSObject<BSGPhasedStartup>

#pragma mark Mandatory Methods

+ (instancetype) sharedInstance;

#pragma mark Configuration and Internal Functions

@property(nonatomic) std::shared_ptr<SpanStackingHandler> spanStackingHandler;
@property(nonatomic) std::shared_ptr<Tracer> tracer;

@end

NS_ASSUME_NONNULL_END
