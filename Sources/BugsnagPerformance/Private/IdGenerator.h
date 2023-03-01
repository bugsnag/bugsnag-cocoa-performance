//
//  IdGenerator.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceSpanContext.h>

#import <stdlib.h>

namespace bugsnag {

// https://opentelemetry.io/docs/reference/specification/trace/sdk/#id-generators
class IdGenerator {
public:
    static SpanId generateSpanId() noexcept {
        return random<SpanId>();
    }
    
    static TraceId generateTraceId() noexcept {
        return random<TraceId>();
    }
    
private:
    template<typename T> static T random() noexcept {
        T result;
        arc4random_buf(&result, sizeof result);
        return result;
    }
};
}
