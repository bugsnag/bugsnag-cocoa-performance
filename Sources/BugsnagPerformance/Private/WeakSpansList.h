//
//  WeakSpansList.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 08.12.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "BugsnagPerformanceSpan+Private.h"
#import <mutex>

@interface BSGWeakSpanPointer: NSObject

// We use a weak wrapper because NSPointerArray.weakObjectsPointerArray's compact method is broken.
@property(nonatomic,readonly,weak) BugsnagPerformanceSpan *span;

- (instancetype) initWithSpan:(BugsnagPerformanceSpan *)span;

+ (instancetype) pointerWithSpan:(BugsnagPerformanceSpan *)span;

@end

namespace bugsnag {

class WeakSpansList {
public:
    WeakSpansList()
    : spans_([NSMutableArray new])
    {}

    void add(BugsnagPerformanceSpan *span) noexcept {
        auto ptr = [BSGWeakSpanPointer pointerWithSpan:span];
        std::lock_guard<std::mutex> guard(mutex_);
        [spans_ addObject:ptr];
    }

    void compact() noexcept {
        std::lock_guard<std::mutex> guard(mutex_);
        bool canCompact = false;
        for (BSGWeakSpanPointer *ptr in spans_) {
            if (ptr.span.state != SpanStateOpen) {
                canCompact = true;
                break;
            }
        }
        if (canCompact) {
            auto newSpans = [NSMutableArray arrayWithCapacity:spans_.count];
            for (BSGWeakSpanPointer *ptr in spans_) {
                if (ptr.span.state == SpanStateOpen) {
                    [newSpans addObject:ptr];
                }
            }
            spans_ = newSpans;
        }
    }

    void abortAllUnconditionally() noexcept {
        std::lock_guard<std::mutex> guard(mutex_);
        for (BSGWeakSpanPointer *ptr in spans_) {
            [ptr.span abortUnconditionally];
        }
        [spans_ removeAllObjects];
    }

    void abortAllOpen() noexcept {
        std::lock_guard<std::mutex> guard(mutex_);
        for (BSGWeakSpanPointer *ptr in spans_) {
            [ptr.span abortIfOpen];
        }
        [spans_ removeAllObjects];
    }

    NSUInteger count() noexcept {
        std::lock_guard<std::mutex> guard(mutex_);
        return spans_.count;
    }

private:
    std::mutex mutex_;
    NSMutableArray *spans_;
};

}
