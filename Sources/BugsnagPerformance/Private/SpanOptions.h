//
//  SpanOptions.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 15.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "../Private/BugsnagPerformanceSpanOptions+Private.h"
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
                bool isFirstClass)
    : parentContext(parentContext)
    , startTime(startTime)
    , makeContextCurrent(makeContextCurrent)
    , isFirstClass(isFirstClass)
    {}
    
    id<BugsnagPerformanceSpanContext> parentContext;
    CFAbsoluteTime startTime;
    bool makeContextCurrent;
    bool isFirstClass;
};

static inline SpanOptions defaultSpanOptionsForCustom() {
    return SpanOptions(nil, CFAbsoluteTimeGetCurrent(), true, true);
}

static inline SpanOptions SpanOptionsForCustom(BugsnagPerformanceSpanOptions *options) {
    return SpanOptions(options.parentContext,
                       defaultTimeIfNil(options.startTime),
                       options.makeContextCurrent,
                       options.wasFirstClassSet ? options.isFirstClass : true);
}

static inline SpanOptions defaultSpanOptionsForInternal() {
    return SpanOptions(nil, CFAbsoluteTimeGetCurrent(), true, false);
}

static inline SpanOptions defaultSpanOptionsForViewLoad() {
    // TODO: This will check the stack for a view load in a later PR
    return SpanOptions(nil, CFAbsoluteTimeGetCurrent(), true, true);
}

static inline SpanOptions SpanOptionsForViewLoad(BugsnagPerformanceSpanOptions *options) {
    return SpanOptions(options.parentContext,
                       defaultTimeIfNil(options.startTime),
                       options.makeContextCurrent,
                       options.wasFirstClassSet ? options.isFirstClass : true);
}

static inline SpanOptions defaultSpanOptionsForNetwork(CFAbsoluteTime startTime) {
    return SpanOptions(nil, startTime, true, false);
}
}

