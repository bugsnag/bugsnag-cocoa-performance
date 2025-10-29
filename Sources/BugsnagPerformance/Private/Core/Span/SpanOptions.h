//
//  SpanOptions.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 15.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanOptions.h>
#import "../../Utils/Utils.h"
#import "../Configuration/Metrics.h"
#import "SpanContext.h"

namespace bugsnag {

class SpanOptions {
public:
    SpanOptions(BugsnagPerformanceSpanContext *parentContext,
                CFAbsoluteTime startTime,
                bool makeCurrentContext,
                BSGTriState firstClass,
                MetricsOptions metricsOptions)
    : parentContext(parentContext)
    , startTime(startTime)
    , makeCurrentContext(makeCurrentContext)
    , firstClass(firstClass)
    , metricsOptions(metricsOptions)
    {}
    
    SpanOptions(BugsnagPerformanceSpanOptions *options)
    : SpanOptions(options.parentContext,
                  dateToAbsoluteTime(options.startTime),
                  options.makeCurrentContext,
                  options.firstClass,
                  options.metricsOptions)
    {}
    
    SpanOptions()
    // These defaults must match the defaults in BugsnagPerformanceSpanOptions.m
    : SpanOptions(getDefaultSpanContext(),
                  CFABSOLUTETIME_INVALID,
                  true,
                  BSGTriStateUnset,
                  MetricsOptions())
    {}
    
    BugsnagPerformanceSpanContext *parentContext{nil};
    CFAbsoluteTime startTime{CFABSOLUTETIME_INVALID};
    bool makeCurrentContext{false};
    BSGTriState firstClass{BSGTriStateUnset};
    MetricsOptions metricsOptions;
};

}
