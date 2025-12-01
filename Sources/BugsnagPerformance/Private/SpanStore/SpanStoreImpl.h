//
//  SpanStoreImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 10/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "SpanStore.h"
#import "../SpanStackingHandler.h"
#import "../WeakSpansList.h"

#import <mutex>

namespace bugsnag {

class SpanStoreImpl: public SpanStore {
public:
    SpanStoreImpl(std::shared_ptr<SpanStackingHandler> spanStackingHandler) noexcept
    : spanStackingHandler_(spanStackingHandler)
    , blockedSpans_([NSMutableArray new])
    , potentiallyOpenSpans_(std::make_shared<WeakSpansList>()) {}
    
    void addNewSpan(BugsnagPerformanceSpan *span, bool makeCurrentContext) noexcept;
    void removeSpan(BugsnagPerformanceSpan *span) noexcept;
    void addSpanToBlocked(BugsnagPerformanceSpan *span) noexcept;
    void removeSpanFromBlocked(BugsnagPerformanceSpan *span) noexcept;
    void performActionAndClearOpenSpans(void (^action)(BugsnagPerformanceSpan *span)) noexcept;
    bool hasSpanOnCurrentStack(NSString *attribute, NSString *value) noexcept;
    void sweep() noexcept;
    
private:
    std::shared_ptr<SpanStackingHandler> spanStackingHandler_;
    std::shared_ptr<WeakSpansList> potentiallyOpenSpans_;
    NSMutableArray<BugsnagPerformanceSpan *> *blockedSpans_;
    std::mutex blockedSpansMutex_;
    
    SpanStoreImpl() = delete;
};
}
