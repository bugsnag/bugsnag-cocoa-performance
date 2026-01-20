//
//  NetworkLifecycleHandler.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import "../State/NetworkInstrumentationState.h"

namespace bugsnag {

class NetworkLifecycleHandler {
public:
    virtual void onInstrumentationConfigured(bool isEnabled, BugsnagPerformanceNetworkRequestCallback callback) noexcept = 0;
    virtual void onTaskResume(NSURLSessionTask *task) noexcept = 0;
    virtual void onTaskDidFinishCollectingMetrics(NSURLSessionTask *task,
                                                  NSURLSessionTaskMetrics *metrics,
                                                  NSString *ignoreBaseEndpoint) noexcept = 0;
    virtual ~NetworkLifecycleHandler() {}
};
}
