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

typedef void (^BSGSessionTaskResumeCallback)(NSURLSessionTask *);

void bsg_installNSURLSessionTaskPerformance(BSGSessionTaskResumeCallback onResume) noexcept;
