//
//  NetworkSpanReporter.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 22/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import "../PhasedStartup.h"

namespace bugsnag {

class NetworkSpanReporter: public PhasedStartup {
public:
    virtual void reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept = 0;
};
}
