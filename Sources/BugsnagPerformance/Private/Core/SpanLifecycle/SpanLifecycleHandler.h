//
//  SpanLifecycleHandler.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 09/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpanCondition.h>
#import "../Span/SpanOptions.h"
#import "../PhasedStartup.h"

namespace bugsnag {

class SpanLifecycleHandler: public PhasedStartup {
public:
    virtual void onSpanStarted(BugsnagPerformanceSpan *span, const SpanOptions &options) noexcept = 0;
    virtual void onSpanEndSet(BugsnagPerformanceSpan *span) noexcept = 0;
    virtual void onSpanClosed(BugsnagPerformanceSpan *span) noexcept = 0;
    virtual BugsnagPerformanceSpanCondition *onSpanBlocked(BugsnagPerformanceSpan *blocked, NSTimeInterval timeout) noexcept = 0;
    virtual void onSpanCancelled(BugsnagPerformanceSpan *span) noexcept = 0;
    virtual ~SpanLifecycleHandler() {}
};
}

