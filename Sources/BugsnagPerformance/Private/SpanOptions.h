//
//  SpanOptions.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 15.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanOptions.h>
#import "Utils.h"

namespace bugsnag {

class SpanOptions {
public:
    SpanOptions(BugsnagPerformanceSpanContext *parentContext,
                CFAbsoluteTime startTime,
                bool makeCurrentContext,
                BSGFirstClass firstClass)
    : parentContext(parentContext)
    , startTime(startTime)
    , makeCurrentContext(makeCurrentContext)
    , firstClass(firstClass)
    {}
    
    SpanOptions(BugsnagPerformanceSpanOptions *options)
    : SpanOptions(options.parentContext,
                  dateToAbsoluteTime(options.startTime),
                  options.makeCurrentContext,
                  options.firstClass)
    {}
    
    SpanOptions()
    // These defaults must match the defaults in BugsnagPerformanceSpanOptions.m
    : SpanOptions(nil,
                  CFABSOLUTETIME_INVALID,
                  true,
                  BSGFirstClassUnset)
    {}
    
    BugsnagPerformanceSpanContext *parentContext{nil};
    CFAbsoluteTime startTime{CFABSOLUTETIME_INVALID};
    bool makeCurrentContext{false};
    BSGFirstClass firstClass{BSGFirstClassUnset};
};

}
