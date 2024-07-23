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

typedef enum {
    AbortOnSpanDestroy,
    EndOnSpanDestroy
} SpanDestroyAction;

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

    ~Span() {
        switch(spanDestroyAction) {
            case AbortOnSpanDestroy:
                BSGLogDebug(@"Span::~Span(): for span %@. Action = Abort", data_->name);
                abortIfOpen();
                break;
            case EndOnSpanDestroy:
                BSGLogDebug(@"Span::~Span(): for span %@. Action = End", data_->name);
                end(CFAbsoluteTimeGetCurrent());
                break;
        }
    }

    void setAttribute(NSString *attributeName, id value) noexcept {
        data_->setAttribute(attributeName, value);
    }

    void setAttributes(NSDictionary *attributes) noexcept {
        // This doesn't have to be thread safe because this method is never called
        // after the span is started.
        auto data = data_;
        if (!isEnded_ && data != nullptr) {
            data->setAttributes(attributes);
        }
    }

    bool hasAttribute(NSString *attributeName, id value) noexcept {
        auto data = data_;
        if (!isEnded_ && data != nullptr) {
            return data->hasAttribute(attributeName, value);
        }
        return false;
    }

    id getAttribute(NSString *attributeName) noexcept {
        return data_->attributes[attributeName];
    }

    bool isEnded(void) {
        return isEnded_;
    }

    void abortIfOpen() noexcept {
        BSGLogDebug(@"Span::abortIfOpen(): isEnded_ = %s", isEnded_ ? "true" : "false");
        if (!isEnded_) {
            data_->markInvalid();
            isEnded_ = true;
        }
    }

    void abortUnconditionally() noexcept {
        BSGLogDebug(@"Span::abortUnconditionally()");
        data_->markInvalid();
        isEnded_ = true;
    }

    void end(CFAbsoluteTime time) noexcept {
        BSGLogDebug(@"Span::end(%f)", time);
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
    NSString *name() {return data_->name;}
    CFAbsoluteTime startTime() {return data_->startTime;}
    CFAbsoluteTime endTime() {return data_->endTime;}
    void updateName(NSString *name) {data_->name = name;}
    void updateStartTime(CFAbsoluteTime time) noexcept {
        data_->startTime = time;
        startClock_ = currentMonotonicClockNsecIfUnset(time);
    }
    
    std::shared_ptr<SpanData> data() {return data_;}

public:
    SpanDestroyAction spanDestroyAction{AbortOnSpanDestroy};

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
