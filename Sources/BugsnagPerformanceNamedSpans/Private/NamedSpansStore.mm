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
    auto existingState = stateForName(span.name);
    if (existingState != spanStates_.end()) {
        spanStates_.erase(existingState);
    }
    auto spanState = std::make_shared<NamedSpanState>(span, CFAbsoluteTimeGetCurrent() + timeout_);
    spanStates_.push_back(spanState);
    nameToSpan_[span.name] = std::prev(spanStates_.end());
}

void
NamedSpansStore::remove(BugsnagPerformanceSpan *span) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    auto state = stateForName(span.name);
    if (state != spanStates_.end() && (*state)->span == span) {
        spanStates_.erase(state);
        nameToSpan_.erase(span.name);
    }
}

BugsnagPerformanceSpan *
NamedSpansStore::getSpan(NSString *name) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    auto state = stateForName(name);
    if (state == spanStates_.end()) {
        return nullptr;
    }
    return (*state)->span;
}

#pragma mark Private

void
NamedSpansStore::sweepExpiredSpans() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    
    auto state = spanStates_.begin();
    while (state != spanStates_.end()) {
        if (now > (*state)->expireTime) {
            auto name = (*state)->span.name;
            nameToSpan_.erase(name);
            state = spanStates_.erase(state);
        } else {
            return;
        }
    }
}

std::list<std::shared_ptr<NamedSpanState>>::iterator
NamedSpansStore::stateForName(NSString *name) noexcept {
    auto result = nameToSpan_.find(name);
    if (result == nameToSpan_.end()) {
        return spanStates_.end();
    }
    return (*result).second;
}
