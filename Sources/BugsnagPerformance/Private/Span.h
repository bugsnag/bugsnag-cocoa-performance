//
//  Span.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#pragma once

#import "SpanData.h"
#import "Utils.h"

#import <memory>

namespace bugsnag {

typedef void (^OnSpanEnd)(std::shared_ptr<SpanData>);

// https://opentelemetry.io/docs/reference/specification/trace/api/#span

/**
 * A span represents an OpenTelemetry span as it progresses, and wraps a data object that contains all data accumulated.
 * Calls the specified callback when it ends.
 */
class Span {
public:
    Span(NSString *name,
         TraceId traceId,
         SpanId spanId,
         SpanId parentId,
         CFAbsoluteTime startTime,
         BSGFirstClass firstClass,
         OnSpanEnd onEnd) noexcept
    : data_(std::make_shared<SpanData>(name,
                                       traceId,
                                       spanId,
                                       parentId,
                                       currentTimeIfUnset(startTime),
                                       firstClass))
    , onEnd_(onEnd)
    , startClock_(currentMonotonicClockNsecIfUnset(startTime))
    {};
    
    Span(const Span&) = delete;
    
    void addAttributes(NSDictionary *attributes) noexcept {
        // This doesn't have to be thread safe because this method is never called
        // after the span is started.
        auto data = data_;
        if (!isEnded_ && data != nullptr) {
            data->addAttributes(attributes);
        }
    }

    bool hasAttribute(NSString *attributeName, id value) noexcept {
        auto data = data_;
        if (!isEnded_ && data != nullptr) {
            return data->hasAttribute(attributeName, value);
        }
        return false;
    }

    bool isEnded(void) {
        return isEnded_;
    }

    void end(CFAbsoluteTime time) noexcept {
        bool expected = false;
        if (!isEnded_.compare_exchange_strong(expected, true)) {
            // compare_exchange_strong() returns true only if isEnded_ was exchanged (from false to true).
            // Therefore, a return of false means that no exchange occurred because
            // isEnded_ was already true (i.e. we've already ended).
            return;
        }

        // If our start and end times were both "unset", then it's on us to counter any
        // clock skew using the monotonic clock.
        if (isMonotonicClockValid(startClock_)) {
            auto endClock = currentMonotonicClockNsecIfUnset(time);
            if (isMonotonicClockValid(endClock)) {
                // Calculate using signed int so that an end time < start time doesn't overflow.
                time = data_->startTime + ((double)((int64_t)endClock - (int64_t)startClock_)) / NSEC_PER_SEC;
            }
        }

        data_->endTime = currentTimeIfUnset(time);
        onEnd_(data_);
    }

    TraceId traceId() {return data_->traceId;}
    SpanId spanId() {return data_->spanId;}
    SpanId parentId() {return data_->parentId;}

private:
    std::shared_ptr<SpanData> data_;
    OnSpanEnd onEnd_{nil};
    std::atomic<bool> isEnded_{false};
    uint64_t startClock_{MONOTONIC_CLOCK_INVALID};

    static const uint64_t MONOTONIC_CLOCK_INVALID = 0;

    static bool isMonotonicClockValid(uint64_t clock) {
        return clock != MONOTONIC_CLOCK_INVALID;
    }

    static uint64_t currentMonotonicClockNsecIfUnset(CFAbsoluteTime time) {
        return isCFAbsoluteTimeValid(time) ? MONOTONIC_CLOCK_INVALID : clock_gettime_nsec_np(CLOCK_MONOTONIC);
    }

    static CFAbsoluteTime currentTimeIfUnset(CFAbsoluteTime time) {
        return isCFAbsoluteTimeValid(time) ? time : CFAbsoluteTimeGetCurrent();
    }
};

}
