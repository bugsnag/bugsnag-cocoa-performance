//
//  NamedSpansStore.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 22/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NamedSpansStore.h"

using namespace bugsnag;

void
NamedSpansStore::start() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    
    __block auto blockThis = this;
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                                     dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
    
    dispatch_source_set_timer(timer,
                              dispatch_time(DISPATCH_TIME_NOW,
                                            (int64_t)(sweepInterval_ * NSEC_PER_SEC)),
                              (uint64_t)(sweepInterval_ * NSEC_PER_SEC),
                             0);
    
    dispatch_source_set_event_handler(timer, ^{
        blockThis->sweepExpiredSpans();
    });
    
    dispatch_resume(timer);
    timer_ = timer;
}

void
NamedSpansStore::add(BugsnagPerformanceSpan *span) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    auto existingState = nameToSpan_[span.name];
    if (existingState != nil) {
        erase(existingState);
    }
    auto spanState = [BSGNamedSpanState new];
    spanState.span = span;
    spanState.expireTime = CFAbsoluteTimeGetCurrent() + timeout_;
    add(spanState);
}

void
NamedSpansStore::remove(BugsnagPerformanceSpan *span) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    auto state = nameToSpan_[span.name];
    if (state.span == span) {
        erase(state);
    }
}

BugsnagPerformanceSpan *
NamedSpansStore::getSpan(NSString *name) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    return nameToSpan_[name].span;
}

#pragma mark Private

void
NamedSpansStore::add(BSGNamedSpanState *state) noexcept {
    state.previous = last_;
    last_.next = state;
    if (first_ == nil) {
        first_ = state;
    }
    last_ = state;
    nameToSpan_[state.span.name] = state;
}

void
NamedSpansStore::erase(BSGNamedSpanState *state) noexcept {
    auto next = state.next;
    auto previous = state.previous;
    next.previous = previous;
    previous.next = next;
    if (state == first_) {
        first_ = next;
    }
    if (state == last_) {
        last_ = previous;
    }
    nameToSpan_[state.span.name] = nil;
}

void
NamedSpansStore::sweepExpiredSpans() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    
    auto state = first_;
    while (state != nil) {
        if (now > state.expireTime) {
            erase(state);
            state = state.next;
        } else {
            return;
        }
    }
}
