//
//  SpanOptions.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 15.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpanOptions.h>
#import "Utils.h"

namespace bugsnag {

static inline CFAbsoluteTime defaultTimeIfNil(NSDate *date) {
    if (date == nil) {
        return CFAbsoluteTimeGetCurrent();
    }
    return dateToAbsoluteTime(date);
}

class SpanOptions {
public:
    SpanOptions(id<BugsnagPerformanceSpanContext> parentContext,
                CFAbsoluteTime startTime,
                bool makeContextCurrent,
                BSGFirstClass isFirstClass)
    : parentContext(parentContext)
    , startTime(startTime)
    , makeContextCurrent(makeContextCurrent)
    , isFirstClass(isFirstClass)
    {}
    
    SpanOptions(BugsnagPerformanceSpanOptions *options)
    : parentContext(options.parentContext)
    , startTime(defaultTimeIfNil(options.startTime))
    , makeContextCurrent(options.makeContextCurrent)
    , isFirstClass(options.isFirstClass)
    {}
    
    id<BugsnagPerformanceSpanContext> parentContext{nil};
    CFAbsoluteTime startTime{0};
    bool makeContextCurrent{false};
    BSGFirstClass isFirstClass{BSGFirstClassUnset};
};

static inline SpanOptions defaultSpanOptionsForCustom() {
    return SpanOptions(nil, CFAbsoluteTimeGetCurrent(), false, BSGFirstClassYes);
}

static inline SpanOptions defaultSpanOptionsForInternal() {
    return SpanOptions(nil, CFAbsoluteTimeGetCurrent(), false, BSGFirstClassUnset);
}

static inline SpanOptions defaultSpanOptionsForViewLoad() {
    // TODO: This will check the stack for a view load in a later PR
    return SpanOptions(nil, CFAbsoluteTimeGetCurrent(), false, BSGFirstClassYes);
}

static inline SpanOptions defaultSpanOptionsForNetwork(CFAbsoluteTime startTime) {
    return SpanOptions(nil, startTime, false, BSGFirstClassUnset);
}
}

