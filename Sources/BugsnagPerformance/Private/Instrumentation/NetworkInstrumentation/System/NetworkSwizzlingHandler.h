//
//  NetworkSwizzlingHandler.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 01/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^BSGSessionTaskResumeCallback)(NSURLSessionTask *);
typedef bool (^BSGIsEnabledCallback)();

namespace bugsnag {

class NetworkSwizzlingHandler {
public:
    virtual void instrumentSession(id<NSURLSessionTaskDelegate> taskDelegate, BSGIsEnabledCallback isEnabled) noexcept = 0;
    virtual void instrumentTask(Class cls, BSGSessionTaskResumeCallback onResume) noexcept = 0;
    virtual ~NetworkSwizzlingHandler() {}
};
}
