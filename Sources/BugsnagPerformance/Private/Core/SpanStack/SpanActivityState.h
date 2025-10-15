//
//  SpanActivityState.h
//  BugsnagPerformance-iOS
//
//  Created by Robert Bartoszewski on 24/05/2023.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "../Span/BugsnagPerformanceSpan+Private.h"
#import <os/activity.h>

namespace bugsnag {
class SpanActivityState {
public:
    SpanActivityState(
                      BugsnagPerformanceSpan *span,
                      os_activity_scope_state_s activityState,
                      os_activity_id_t activityId,
                      os_activity_id_t parentActivityId) noexcept
    : span(span)
    , activityState(activityState)
    , activityId(activityId)
    , parentActivityId(parentActivityId)
    , spanId(span.spanId) {};
    ~SpanActivityState() {};
    
    BugsnagPerformanceSpan *__weak span;
    os_activity_scope_state_s activityState;
    uint64_t childSpansCount{0};
    os_activity_id_t activityId;
    os_activity_id_t parentActivityId;
    SpanId spanId;
    bool isDumped{false};
};
}

