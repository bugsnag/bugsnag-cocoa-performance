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

class SpanOptions {
public:
    SpanOptions(id<BugsnagPerformanceSpanContext> parentContext,
                CFAbsoluteTime startTime,
                bool makeContextCurrent,
                BSGFirstClass firstClass)
    : parentContext(parentContext)
    , startTime(startTime)
    , makeContextCurrent(makeContextCurrent)
    , firstClass(firstClass)
    {}
    
    SpanOptions(BugsnagPerformanceSpanOptions *options)
    : SpanOptions(options.parentContext,
                  options.startTime == nil ? CFAbsoluteTimeGetCurrent() : dateToAbsoluteTime(options.startTime),
                  options.makeCurrentContext,
                  options.firstClass)
    {}
    
    SpanOptions()
    // These defaults must match the defaults in BugsnagPerformanceSpanOptions.m
    : SpanOptions(nil,
                  CFAbsoluteTimeGetCurrent(),
                  true,
                  BSGFirstClassUnset)
    {}
    
    id<BugsnagPerformanceSpanContext> parentContext{nil};
    CFAbsoluteTime startTime{0};
    bool makeContextCurrent{false};
    BSGFirstClass firstClass{BSGFirstClassUnset};
};

}
