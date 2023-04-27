//
//  NSURLSessionTask+Instrumentation.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 25.04.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import "../../Tracer.h"

#import <memory>

void bsg_installNSURLSessionTaskPerformance(std::shared_ptr<bugsnag::Tracer> tracer) noexcept;

extern const void *bsg_associatedNetworkSpanKey;
