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
    : SpanOptions(options.parentContext,
                  defaultTimeIfNil(options.startTime),
                  options.makeContextCurrent,
                  options.isFirstClass)
    {}
    
    SpanOptions()
    // These defaults must match the defaults in BugsnagPerformanceSpanOptions.m
    : SpanOptions(nil,
                  CFAbsoluteTimeGetCurrent(),
                  true,
                  BSGFirstClassUnset)
    {}
    
    id<BugsnagPerformanceSpanContext> parentContext;
    CFAbsoluteTime startTime;
    bool makeContextCurrent;
    BSGFirstClass isFirstClass;
};

static inline SpanOptions defaultSpanOptionsForCustom() {
    return SpanOptions(nil, CFAbsoluteTimeGetCurrent(), true, BSGFirstClassYes);
}

static inline SpanOptions defaultSpanOptionsForInternal() {
    return SpanOptions(nil, CFAbsoluteTimeGetCurrent(), true, BSGFirstClassUnset);
}

static inline SpanOptions defaultSpanOptionsForViewLoad() {
    // TODO: This will check the stack for a view load in a later PR
    return SpanOptions(nil, CFAbsoluteTimeGetCurrent(), true, BSGFirstClassYes);
}

static inline SpanOptions defaultSpanOptionsForNetwork(CFAbsoluteTime startTime) {
    return SpanOptions(nil, startTime, true, BSGFirstClassUnset);
}
}

