//
//  AsyncToSyncTask.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <mutex>

typedef void (^TaskCompletion)(bool);
typedef void (^TaskWork)(TaskCompletion);

namespace bugsnag {

class AsyncToSyncTask {
public:
    AsyncToSyncTask(TaskWork work) noexcept
    : work_(work) {}
    
    bool executeSync();
    
    ~AsyncToSyncTask() {}
    
private:
    TaskWork work_{nullptr};
    
    std::recursive_mutex mutex_;
};
}
