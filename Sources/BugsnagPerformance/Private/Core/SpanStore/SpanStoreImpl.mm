//
//  SpanStoreImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 10/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "SpanStoreImpl.h"

void
SpanStoreImpl::addNewSpan(BugsnagPerformanceSpan *span, bool makeCurrentContext) noexcept {
    if (makeCurrentContext) {
        spanStackingHandler_->push(span);
    }
    potentiallyOpenSpans_->add(span);
}

void
SpanStoreImpl::removeSpan(BugsnagPerformanceSpan *span) noexcept {
    spanStackingHandler_->onSpanClosed(span.spanId);
}

void
SpanStoreImpl::addSpanToBlocked(BugsnagPerformanceSpan *span) noexcept {
    std::lock_guard<std::mutex> guard(blockedSpansMutex_);
    [blockedSpans_ addObject:span];
}

void
SpanStoreImpl::removeSpanFromBlocked(BugsnagPerformanceSpan *span) noexcept {
    std::lock_guard<std::mutex> guard(blockedSpansMutex_);
    [blockedSpans_ removeObject:span];
}

void
SpanStoreImpl::performActionAndClearOpenSpans(void (^action)(BugsnagPerformanceSpan *span)) noexcept {
    potentiallyOpenSpans_->performActionAndClear(action);
}

bool
SpanStoreImpl::hasSpanOnCurrentStack(NSString *attribute, NSString *value) noexcept {
    return spanStackingHandler_->hasSpanWithAttribute(attribute, value);
}

void
SpanStoreImpl::sweep() noexcept {
    constexpr unsigned minEntriesBeforeCompacting = 10000;
    if (potentiallyOpenSpans_->count() >= minEntriesBeforeCompacting) {
        potentiallyOpenSpans_->compact();
    }
}
