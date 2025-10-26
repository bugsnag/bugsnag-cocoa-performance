//
//  UploadHandler.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>

#import "../../Core/Worker/AsyncToSyncTask.h"

@class BugsnagPerformanceSpan;

namespace bugsnag {
class UploadHandler {
public:
    virtual void uploadPValueRequest(TaskCompletion completion) noexcept = 0;
    virtual void uploadSpans(NSArray<BugsnagPerformanceSpan *> *spans, TaskCompletion completion) noexcept = 0;
    virtual void sendRetries(TaskCompletion completion) noexcept = 0;
    
    virtual ~UploadHandler() {};
};
}
