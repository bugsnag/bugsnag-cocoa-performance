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

typedef void (^OnSpanEnd)(std::unique_ptr<SpanData>);

// https://opentelemetry.io/docs/reference/specification/trace/api/#span

/**
 * A span represents an OpenTelemetry span as it progresses, and wraps a data object that contains all data accumulated.
 * Calls the specified callback when it ends.
 */
class Span {
public:
    Span(std::unique_ptr<SpanData> data, OnSpanEnd onEnd) noexcept
    : data_(std::move(data))
    , onEnd_(onEnd)
    {};
    
    Span(const Span&) = delete;
    
    void addAttributes(NSDictionary *attributes) noexcept {
        data_ ? data_->addAttributes(attributes) : (void)0;
    }
    
    void end(CFAbsoluteTime time) noexcept {
        if (!data_) {
            return;
        }
        data_->endTime = time;
        onEnd_(std::move(data_));
    }

    TraceId traceId() {return data_->traceId;}
    SpanId spanId() {return data_->spanId;}

private:
    std::unique_ptr<SpanData> data_;
    OnSpanEnd onEnd_;
};

}
