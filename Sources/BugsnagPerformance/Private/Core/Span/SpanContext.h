//
//  SpanContext.h
//  BugsnagPerformance
//
//  Created by Daria Bialobrzeska on 27/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//
#ifndef BUGSNAGPERFORMANCE_SPANCONTEXT_H
#define BUGSNAGPERFORMANCE_SPANCONTEXT_H

#import <BugsnagPerformance/BugsnagPerformanceSpanContext.h>

namespace bugsnag {

static BugsnagPerformanceSpanContext *defaultContext = nil;

BugsnagPerformanceSpanContext *getDefaultSpanContext();
}

#endif // BUGSNAGPERFORMANCE_SPANCONTEXT_H
