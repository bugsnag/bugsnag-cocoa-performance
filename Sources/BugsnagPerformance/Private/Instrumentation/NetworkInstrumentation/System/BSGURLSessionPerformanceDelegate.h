//
//  BSGURLSessionPerformanceDelegate.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 01/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "../Lifecycle/NetworkLifecycleHandler.h"
#import "../../../Core/BSGPhasedStartup.h"
#import <memory>

using namespace bugsnag;

NS_ASSUME_NONNULL_BEGIN

@interface BSGURLSessionPerformanceDelegate : NSObject <NSURLSessionTaskDelegate, BSGPhasedStartup>
- (instancetype) initWithLifecycleHandler:(std::shared_ptr<NetworkLifecycleHandler>)lifecycleHandler;
@end

NS_ASSUME_NONNULL_END
