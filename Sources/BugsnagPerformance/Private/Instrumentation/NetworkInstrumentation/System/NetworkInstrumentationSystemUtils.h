//
//  NetworkInstrumentationSystemUtils.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

#import <objc/runtime.h>

namespace bugsnag {

class NetworkInstrumentationSystemUtils {
public:
    virtual NSArray<Class> *taskClassesToInstrument() noexcept = 0;
    virtual NSURLRequest *taskRequest(NSURLSessionTask *task, NSError **error) noexcept = 0;
    virtual NSURLRequest *taskCurrentRequest(NSURLSessionTask *task, NSError **error) noexcept = 0;
    virtual ~NetworkInstrumentationSystemUtils() {}
};
}
