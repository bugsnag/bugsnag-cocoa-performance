//
//  NamedSpanState.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 22/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>

namespace bugsnag {
class NamedSpanState {
public:
    NamedSpanState(BugsnagPerformanceSpan *span,
                   CFAbsoluteTime expireTime) noexcept
    : span(span)
    , expireTime(expireTime) {};
    ~NamedSpanState() {};
    
    BugsnagPerformanceSpan *span;
    CFAbsoluteTime expireTime;
};
}
