//
//  NamedSpansStore.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 22/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>
#import "NamedSpanState.h"
#import <map>
#import <list>
#import <mutex>

namespace bugsnag {
class NamedSpansStore {
public:
    NamedSpansStore(NSTimeInterval timeout,
                       NSTimeInterval sweepInterval) noexcept
    : timeout_(timeout)
    , sweepInterval_(sweepInterval) {}
    
    ~NamedSpansStore() noexcept {
        if (timer_ != nullptr) {
            dispatch_cancel(timer_);
        }
    };
    
    void start() noexcept;
    void add(BugsnagPerformanceSpan *span) noexcept;
    void remove(BugsnagPerformanceSpan *span) noexcept;
    BugsnagPerformanceSpan *getSpan(NSString *name) noexcept;
private:
    std::map<NSString *, std::list<std::shared_ptr<NamedSpanState>>::iterator> nameToSpan_{};
    std::list<std::shared_ptr<NamedSpanState>> spanStates_{};
    std::mutex mutex_;
    dispatch_source_t timer_;
    NSTimeInterval timeout_;
    NSTimeInterval sweepInterval_;
    
    std::list<std::shared_ptr<NamedSpanState>>::iterator stateForName(NSString *name) noexcept;
    void sweepExpiredSpans() noexcept;
};
}
