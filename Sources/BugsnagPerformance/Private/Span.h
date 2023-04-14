//
//  Span.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#pragma once

#import "SpanData.h"

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
    Span(std::shared_ptr<SpanData> data, OnSpanEnd onEnd) noexcept
    : data_(data)
    , onEnd_(onEnd)
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

        data_->endTime = time;
        onEnd_(data_);
    }

    TraceId traceId() {return data_->traceId;}
    SpanId spanId() {return data_->spanId;}

private:
    std::shared_ptr<SpanData> data_;
    OnSpanEnd onEnd_{nil};
    std::atomic<bool> isEnded_{false};
};

}
