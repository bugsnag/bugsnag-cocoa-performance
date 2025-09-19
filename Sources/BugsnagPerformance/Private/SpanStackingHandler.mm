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
    NSLog(@"DARIA_LOG SPAN STACKING HANDLER: Pushing span %@, with attributes: %@", span.name, span.attributes);
    os_activity_id_t parentActivityId = currentActivityId();
    os_activity_scope_state_s activityState;
    os_activity_t activity = os_activity_create("BSGSpanContext", OS_ACTIVITY_CURRENT, OS_ACTIVITY_FLAG_DEFAULT);
    os_activity_id_t activityId = os_activity_get_identifier(activity, nil);
    NSLog(@"DARIA_LOG SPAN STACKING HANDLER: Created activity with id: %llu, parent id: %llu, for span: %@", activityId, parentActivityId, span.name);
    os_activity_scope_enter(activity, &activityState);
    
    auto newState = std::make_shared<SpanActivityState>(span, activityState, activityId, parentActivityId);
    this->activityIdToSpanState_[activityId] = newState;
    this->spanIdToSpanState_[span.spanId] = newState;
    std::shared_ptr<SpanActivityState> parentState = spanStateForActivity(parentActivityId);
    if (parentState != nullptr) {
        parentState->childSpansCount++;
    }
    __block auto blockThis = this;
    span.onDumped = ^void(BugsnagPerformanceSpan *dumpedSpan) {
        std::lock_guard<std::mutex> blockGuard(blockThis->mutex_);
        NSLog(@"DARIA_LOG SPAN STACKING HANDLER: onDumped called for span: %@", dumpedSpan.name);
        auto state = blockThis->spanStateForSpan(dumpedSpan.spanId);
        if (state != nullptr) {
            state->isDumped = true;
            blockThis->removeSpan(dumpedSpan.spanId);
        }
    };
}

BugsnagPerformanceSpan *
SpanStackingHandler::currentSpan() {
    std::lock_guard<std::mutex> guard(mutex_);

    NSLog(@"DARIA_LOG SPAN STACKING HANDLER: currentSpan called");
    std::shared_ptr<SpanActivityState> state = spanStateForActivity(currentActivityId());
    if (state == nullptr) {
        NSLog(@"DARIA_LOG SPAN STACKING HANDLER: currentSpan state is nil");
        return nullptr;
    }
    if (!(state->span.state == SpanStateOpen)) {
        NSLog(@"DARIA_LOG SPAN STACKING HANDLER: currentSpan state is not open");
        return nullptr;
    }

    NSLog(@"DARIA_LOG SPAN STACKING HANDLER: currentSpan is: %@", state->span.name);
    return state->span;
}

void
SpanStackingHandler::onSpanClosed(SpanId spanId) {
    std::lock_guard<std::mutex> guard(mutex_);
    NSLog(@"DARIA_LOG SPAN STACKING HANDLER: onSpanClosed called for spanId: %llu", spanId);
    removeSpan(spanId);
}

bool
SpanStackingHandler::hasSpanWithAttribute(NSString *attribute, NSString *value) {
    std::lock_guard<std::mutex> guard(mutex_);
    NSLog(@"DARIA_LOG SPAN STACKING HANDLER: hasSpanWithAttribute called for attribute: %@, value: %@", attribute, value);
    std::shared_ptr<SpanActivityState> state = spanStateForActivity(currentActivityId());
    while (state != nullptr) {
        NSLog(@"DARIA_LOG SPAN STACKING HANDLER: hasSpanWithAttribute state not nil");
        if (state->span.state == SpanStateOpen) {
            if ([state->span hasAttribute:attribute withValue:value]) {
                NSLog(@"DARIA_LOG SPAN STACKING HANDLER: hasSpanWithAttribute found matching span: %@", state->span.name);
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
    BSGLogError("DARIA_LOG SpanStackingHandler::findSpanForCategory, check for activity id: %llu", currentActivityId());
    while (state != nullptr) {
        BSGLogError("DARIA_LOG SpanStackingHandler::findSpanForCategory state not nil for activityId: %llu", state->activityId);
        if (state->span.state == SpanStateOpen) {
            BSGLogError("DARIA_LOG SpanStackingHandler::findSpanForCategory span is open, name: %@", state->span.name);
            if ([state->span hasAttribute:@"bugsnag.span.category" withValue:categoryName]) {
                BSGLogError("DARIA_LOG SpanStackingHandler::findSpanForCategory span has needed category");
                return state->span;
            }
        }
        state = spanStateForActivity(state->parentActivityId);
    }
    BSGLogError("DARIA_LOG SpanStackingHandler::findSpanForCategory end");
    return nil;
}

void
SpanStackingHandler::sweep(SpanId spanId) {
    BSGLogError("DARIA_LOG SpanStackingHandler::sweep");
    std::shared_ptr<SpanActivityState> state = spanStateForSpan(spanId);
    while (state != nullptr) {
        BSGLogError("DARIA_LOG SpanStackingHandler::sweep checking state for span: %@", state->span.name);
        if ((state->span != nullptr && state->span.state == SpanStateOpen && !(state->isDumped))) {
            BSGLogError("DARIA_LOG SpanStackingHandler::sweep span is still open or not dumped");
            return;
        }
        if (currentActivityId() == state->activityId) {
            os_activity_scope_leave(&(state->activityState));
        }
        if (state->childSpansCount <= 0) {
            //spanIdToSpanState_.erase(state->spanId);
            //activityIdToSpanState_.erase(state->activityId);
            BSGLogError("DARIA_LOG SpanStackingHandler::sweep erased span: %@", state->span.name);
        }
        state = spanStateForActivity(state->parentActivityId);
    }
}

void
SpanStackingHandler::removeSpan(SpanId spanId) {
    BSGLogError("DARIA_LOG SpanStackingHandler::removeSpan for spanId: %llu", spanId);
    std::shared_ptr<SpanActivityState> state = spanStateForSpan(spanId);
    if (state != nullptr && state->parentActivityId != 0) {
        BSGLogError("DARIA_LOG SpanStackingHandler::removeSpan for span %@", state->span.name);
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
