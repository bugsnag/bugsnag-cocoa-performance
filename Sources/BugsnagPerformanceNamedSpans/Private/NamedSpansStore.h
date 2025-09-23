//
//  NamedSpansStore.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 22/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>
#import "BSGNamedSpanState.h"
#import <map>
#import <list>
#import <mutex>
#import <unordered_map>

namespace bugsnag {

struct NSStringHash {
    std::size_t operator()(NSString *str) const noexcept {
        return std::hash<std::string>{}([str UTF8String]);
    }
};

struct NSStringEqual {
    bool operator()(NSString *lhs, NSString *rhs) const noexcept {
        return [lhs isEqualToString:rhs];
    }
};

class NamedSpansStore {
public:
    NamedSpansStore(NSTimeInterval timeout,
                       NSTimeInterval sweepInterval) noexcept
    : timeout_(timeout)
    , sweepInterval_(sweepInterval)
    , nameToSpan_([NSMutableDictionary<NSString *, BSGNamedSpanState *> dictionary]) {}
    
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
    NSMutableDictionary<NSString *, BSGNamedSpanState *> *nameToSpan_;
    std::mutex mutex_;
    dispatch_source_t timer_;
    NSTimeInterval timeout_;
    NSTimeInterval sweepInterval_;
    BSGNamedSpanState *first_;
    BSGNamedSpanState *last_;
    
    void add(BSGNamedSpanState *state) noexcept;
    void erase(BSGNamedSpanState *state) noexcept;
    void sweepExpiredSpans() noexcept;
};
}
