//
//  SpanData.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 06/10/2022.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceSpan.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanOptions.h>

#import "Utils.h"
#import "IdGenerator.h"
#import "SpanKind.h"
#import <mutex>

namespace bugsnag {

typedef enum {
    SpanStateOpen,
    SpanStateEnded,
    SpanStateAborted,
} SpanState;

/**
 * SpanData is a representation of all data collected by a span.
 */
class SpanData {
public:
    SpanData(NSString *name,
             TraceId traceId,
             SpanId spanId,
             SpanId parentId,
             CFAbsoluteTime startTime,
             BSGFirstClass firstClass) noexcept;

    SpanData(const SpanData&) = delete;

    void setAttribute(NSString *attributeName, id value) noexcept;

    void setAttributes(NSDictionary *attributes) noexcept;

    bool hasAttribute(NSString *attributeName, id value) noexcept;

    void updateSamplingProbability(double value) noexcept;

    SpanState getState() {return state_;}

    /**
     * End the span.
     * Returns false if the span was already ended.
     */
    bool endSpan() {
        SpanState expectedCurrentState = SpanStateOpen;
        bool wasOpen = state_.compare_exchange_strong(expectedCurrentState, SpanStateEnded);
        BSGLogDebug(@"SpanData::endSpan(): %@, wasOpen = %s", name, wasOpen ? "true" : "false");
        return wasOpen;
    }

    /**
     * Abort the span, but only if it's open.
     * Returns true if the span was successfully aborted.
     */
    bool abortSpanIfOpen() {
        SpanState expectedCurrentState = SpanStateOpen;
        bool wasOpen = state_.compare_exchange_strong(expectedCurrentState, SpanStateAborted);
        BSGLogDebug(@"SpanData::abortSpanIfOpen(): %@, wasOpen = %s", name, wasOpen ? "true" : "false");
        return wasOpen;
    }

    void abortSpan() {
        BSGLogDebug(@"SpanData::abortSpan(): %@", name);
        state_ = SpanStateAborted;
    }

    TraceId traceId{0};
    SpanId spanId{0};
    SpanId parentId{0};
    NSString *name{nil};
    SpanKind kind{SPAN_KIND_INTERNAL};
    NSMutableDictionary *attributes{nil};
    double samplingProbability{0};
    CFAbsoluteTime startTime{0};
    CFAbsoluteTime endTime{0};
    BSGFirstClass firstClass{BSGFirstClassUnset};

private:
    std::mutex mutex_;
    std::atomic<SpanState> state_{SpanStateOpen};
};

}
