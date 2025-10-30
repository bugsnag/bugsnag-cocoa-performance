//
//  SpanContext.m
//  BugsnagPerformance
//
//  Created by Daria Bialobrzeska on 27/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//
#import "SpanContext.h"

namespace bugsnag {

    BugsnagPerformanceSpanContext *getDefaultSpanContext() {
        if (defaultContext == nil) {
            defaultContext = [[BugsnagPerformanceSpanContext alloc] initWithTraceId:{.hi = 0, .lo = 0 } spanId:0];
        }

        return defaultContext;
    }
}
