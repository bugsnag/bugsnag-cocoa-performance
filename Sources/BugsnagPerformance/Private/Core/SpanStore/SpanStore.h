//
//  SpanStore.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 10/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

namespace bugsnag {

/**
 * SpanStore keeps track of all open spans. It allows adding and removing spans,
 * quering the current stack as well as performing actions on all open spans
 * (e.g., when the app goes to background).
 */
class SpanStore {
public:
    virtual void addNewSpan(BugsnagPerformanceSpan *span, bool makeCurrentContext) noexcept = 0;
    virtual void removeSpan(BugsnagPerformanceSpan *span) noexcept = 0;
    virtual void performActionAndClearOpenSpans(void (^action)(BugsnagPerformanceSpan *span)) noexcept = 0;
    
    virtual void addSpanToBlocked(BugsnagPerformanceSpan *span) noexcept = 0;
    virtual void removeSpanFromBlocked(BugsnagPerformanceSpan *span) noexcept = 0;
    
    virtual bool hasSpanOnCurrentStack(NSString *attribute, NSString *value) noexcept = 0;
    virtual void sweep() noexcept = 0;
    
    virtual ~SpanStore() {}
};
}
