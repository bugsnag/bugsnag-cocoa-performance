//
//  NetworkInstrumentation.m
//  
//
//  Created by Karl Stenerud on 14.10.22.
//

#import "NetworkInstrumentation.h"

#import "../BugsnagPerformanceSpan+Private.h"
#import "../Span.h"
#import "../Tracer.h"

#import <objc/runtime.h>

#if 0
#define Trace NSLog
#else
#define Trace(...)
#endif

using namespace bugsnag;

void
NetworkInstrumentation::start() noexcept {
    Trace(@"NetworkInstrumentation::start()");
}
