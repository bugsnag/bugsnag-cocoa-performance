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
                BSGFirstClass firstClass,
                bool instrumentRendering)
    : parentContext(parentContext)
    , startTime(startTime)
    , makeCurrentContext(makeCurrentContext)
    , firstClass(firstClass)
    , instrumentRendering(instrumentRendering)
    {}
    
    SpanOptions(BugsnagPerformanceSpanOptions *options)
    : SpanOptions(options.parentContext,
                  dateToAbsoluteTime(options.startTime),
                  options.makeCurrentContext,
                  options.firstClass,
                  options.instrumentRendering)
    {}
    
    SpanOptions()
    // These defaults must match the defaults in BugsnagPerformanceSpanOptions.m
    : SpanOptions(nil,
                  CFABSOLUTETIME_INVALID,
                  true,
                  BSGFirstClassUnset,
                  true)
    {}
    
    BugsnagPerformanceSpanContext *parentContext{nil};
    CFAbsoluteTime startTime{CFABSOLUTETIME_INVALID};
    bool makeCurrentContext{false};
    BSGFirstClass firstClass{BSGFirstClassUnset};
    bool instrumentRendering{true};
};

}
