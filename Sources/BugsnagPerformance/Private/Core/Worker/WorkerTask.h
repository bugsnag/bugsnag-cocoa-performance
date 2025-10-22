//
//  WorkerTask.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

typedef void (^TaskCompletion)(bool);
typedef void (^TaskWork)(TaskCompletion);

namespace bugsnag {

class WorkerTask {
public:
    WorkerTask(TaskWork work) noexcept
    : work_(work) {}
    
    bool executeSync();
    
    ~WorkerTask() {}
    
private:
    TaskWork work_{nullptr};
};
}
