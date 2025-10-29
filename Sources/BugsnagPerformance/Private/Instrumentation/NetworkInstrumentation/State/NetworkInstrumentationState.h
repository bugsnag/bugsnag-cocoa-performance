//
//  NetworkInstrumentationState.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 01/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

NS_ASSUME_NONNULL_BEGIN

@interface NetworkInstrumentationState : NSObject
@property (nonatomic, nullable, strong) BugsnagPerformanceSpan *overallSpan;
@property (nonatomic, nullable) NSURL *url;
@property (nonatomic) BOOL hasBeenVetoed;
@end

NS_ASSUME_NONNULL_END
