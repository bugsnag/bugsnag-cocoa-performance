//
//  NetworkSwizzlingHandlerImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 01/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "NetworkSwizzlingHandler.h"

namespace bugsnag {

class NetworkSwizzlingHandlerImpl: public NetworkSwizzlingHandler {
public:
    void instrumentSession(id<NSURLSessionTaskDelegate> taskDelegate, BSGIsEnabledCallback isEnabled) noexcept;
    void instrumentTask(Class cls, BSGSessionTaskResumeCallback onResume) noexcept;
    
private:
    void instrumentSharedSession(BSGIsEnabledCallback isEnabled) noexcept;
    void instrumentSessionWithConfigurationDelegateQueue(id<NSURLSessionTaskDelegate> taskDelegate,
                                                         BSGIsEnabledCallback isEnabled) noexcept;
};
}
