//
//  ConditionTimeoutExecutor.h
//  BugsnagPerformance-iOS
//
//  Created by Robert Bartoszewski on 24/01/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import "BugsnagPerformanceSpanCondition+Private.h"
#import <map>
#import <mutex>

namespace bugsnag {
class ConditionTimeoutExecutor {
public:
    ConditionTimeoutExecutor() noexcept {};
    ~ConditionTimeoutExecutor() {};
    
    void sheduleTimeout(BugsnagPerformanceSpanCondition *condition, NSTimeInterval timeout) noexcept {
        std::lock_guard<std::mutex> guard(mutex_);
        this->conditionIdToTimer_[condition.conditionId] = [NSTimer scheduledTimerWithTimeInterval:timeout repeats:NO block:^(NSTimer *) {
            [condition didTimeout];
        }];
    }
    
    void cancelTimeout(BugsnagPerformanceSpanCondition *condition) noexcept {
        std::lock_guard<std::mutex> guard(mutex_);
        auto result = conditionIdToTimer_.find(condition.conditionId);
        if (result == conditionIdToTimer_.end()) {
            return;
        }
        auto timer = (*result).second;
        [timer invalidate];
        conditionIdToTimer_.erase(condition.conditionId);
    }
    
private:
    std::map<SpanConditionId, NSTimer *> conditionIdToTimer_{};
    std::mutex mutex_;
};
}
