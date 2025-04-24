//
//  SpanStackingHandler.h
//  BugsnagPerformance-iOS
//
//  Created by Robert B on 24/05/2023.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "BugsnagPerformanceSpan+Private.h"
#import "SpanActivityState.h"
#import <os/activity.h>
#import <map>
#import <mutex>

namespace bugsnag {
class SpanStackingHandler {
public:
    SpanStackingHandler() noexcept;
    ~SpanStackingHandler() {};
    
    void push(BugsnagPerformanceSpan *span);
    BugsnagPerformanceSpan *currentSpan();
    void onSpanClosed(SpanId spanId);

    bool hasSpanWithAttribute(NSString *attribute, NSString *value);
    BugsnagPerformanceSpan *findSpanForCategory(NSString *categoryName);
    
    bool unitTest_isEmpty();
private:
    std::map<os_activity_id_t, std::shared_ptr<SpanActivityState>> activityIdToSpanState_{};
    std::map<SpanId, std::shared_ptr<SpanActivityState>> spanIdToSpanState_{};
    std::mutex mutex_;
    void removeSpan(SpanId spanId);
    os_activity_id_t activityIdForSpan(SpanId spanId);
    std::shared_ptr<SpanActivityState> spanStateForSpan(SpanId spanId);
    std::shared_ptr<SpanActivityState> spanStateForActivity(os_activity_id_t activityId);
    void sweep(SpanId spanId);
};
}
