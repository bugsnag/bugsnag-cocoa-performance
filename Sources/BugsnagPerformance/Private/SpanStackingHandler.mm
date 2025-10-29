//
//  SpanStackingHandler.mm
//  BugsnagPerformance-iOS
//
//  Created by Robert Bartoszewski on 24/05/2023.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpanStackingHandler.h"
#import "BugsnagPerformanceSpan+Private.h"
#import "SpanActivityState.h"
#import <os/activity.h>
#import <memory>

using namespace bugsnag;

SpanStackingHandler::SpanStackingHandler() noexcept {};

static inline os_activity_id_t currentActivityId() {
    return os_activity_get_identifier(OS_ACTIVITY_CURRENT, nil);
}

void
SpanStackingHandler::push(BugsnagPerformanceSpan *span) {
    std::lock_guard<std::mutex> guard(mutex_);
    os_activity_id_t parentActivityId = currentActivityId();
    os_activity_scope_state_s activityState;
    os_activity_t activity = os_activity_create("BSGSpanContext", OS_ACTIVITY_CURRENT, OS_ACTIVITY_FLAG_DEFAULT);
    os_activity_id_t activityId = os_activity_get_identifier(activity, nil);
    os_activity_scope_enter(activity, &activityState);
    
    auto newState = std::make_shared<SpanActivityState>(span, activityState, activityId, parentActivityId);
    this->activityIdToSpanState_[activityId] = newState;
    this->spanIdToSpanState_[span.spanId] = newState;
    std::shared_ptr<SpanActivityState> parentState = spanStateForActivity(parentActivityId);
    if (parentState != nullptr) {
        parentState->childSpansCount++;
    }
    __block auto blockThis = this;
    span.onDumped = ^void(SpanId spanId) {
        std::lock_guard<std::mutex> blockGuard(blockThis->mutex_);
        auto state = blockThis->spanStateForSpan(spanId);
        if (state != nullptr) {
            state->isDumped = true;
            blockThis->removeSpan(spanId);
        }
    };
}

BugsnagPerformanceSpan *
SpanStackingHandler::currentSpan() {
    std::lock_guard<std::mutex> guard(mutex_);
    std::shared_ptr<SpanActivityState> state = spanStateForActivity(currentActivityId());
    if (state == nullptr) {
        return nullptr;
    }
    if (!(state->span.state == SpanStateOpen)) {
        return nullptr;
    }
    return state->span;
}

void
SpanStackingHandler::onSpanClosed(SpanId spanId) {
    std::lock_guard<std::mutex> guard(mutex_);
    removeSpan(spanId);
}

bool
SpanStackingHandler::hasSpanWithAttribute(NSString *attribute, NSString *value) {
    std::lock_guard<std::mutex> guard(mutex_);
    std::shared_ptr<SpanActivityState> state = spanStateForActivity(currentActivityId());
    while (state != nullptr) {
        if (state->span.state == SpanStateOpen) {
            if ([state->span hasAttribute:attribute withValue:value]) {
                return true;
            }
        }
        state = spanStateForActivity(state->parentActivityId);
    }
    return false;
}

BugsnagPerformanceSpan *
SpanStackingHandler::findSpanForCategory(NSString *categoryName) {
    std::lock_guard<std::mutex> guard(mutex_);
    std::shared_ptr<SpanActivityState> state = spanStateForActivity(currentActivityId());
    while (state != nullptr) {
        if (state->span.state == SpanStateOpen) {
            if ([state->span hasAttribute:@"bugsnag.span.category" withValue:categoryName]) {
                return state->span;
            }
        }
        state = spanStateForActivity(state->parentActivityId);
    }
    return nil;
}

void
SpanStackingHandler::sweep(SpanId spanId) {
    std::shared_ptr<SpanActivityState> state = spanStateForSpan(spanId);
    while (state != nullptr) {
        if ((state->span != nullptr && state->span.state == SpanStateOpen && !(state->isDumped))) {
            return;
        }
        if (currentActivityId() == state->activityId) {
            os_activity_scope_leave(&(state->activityState));
        }
        if (state->childSpansCount <= 0) {
            spanIdToSpanState_.erase(state->spanId);
            activityIdToSpanState_.erase(state->activityId);
        }
        state = spanStateForActivity(state->parentActivityId);
    }
}

void
SpanStackingHandler::removeSpan(SpanId spanId) {
    std::shared_ptr<SpanActivityState> state = spanStateForSpan(spanId);
    if (state != nullptr && state->parentActivityId != 0) {
        std::shared_ptr<SpanActivityState> parentState = spanStateForActivity(state->parentActivityId);
        if (parentState != nullptr) {
            parentState->childSpansCount--;
        }
    }
    sweep(spanId);
}

std::shared_ptr<SpanActivityState>
SpanStackingHandler::spanStateForSpan(SpanId spanId) {
    auto result = spanIdToSpanState_.find(spanId);
    if (result == spanIdToSpanState_.end()) {
        return 0;
    }
    return (*result).second;
}

std::shared_ptr<SpanActivityState>
SpanStackingHandler::spanStateForActivity(os_activity_id_t activityId) {
    auto result = activityIdToSpanState_.find(activityId);
    if (result == activityIdToSpanState_.end()) {
        return nullptr;
    }
    return (*result).second;
}

bool
SpanStackingHandler::unitTest_isEmpty() {
    if (activityIdToSpanState_.size() > 0) {
        return false;
    }
    if (spanIdToSpanState_.size() > 0) {
        return false;
    }
    return true;
}
