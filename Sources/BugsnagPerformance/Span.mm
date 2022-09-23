//
//  Span.m
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "Span.h"

static NSString * EncodeSpanKind(SpanKind kind) {
    switch (kind) {
        case SPAN_KIND_UNSPECIFIED: return @"SPAN_KIND_UNSPECIFIED";
        case SPAN_KIND_INTERNAL:    return @"SPAN_KIND_INTERNAL";
        case SPAN_KIND_SERVER:      return @"SPAN_KIND_SERVER";
        case SPAN_KIND_CLIENT:      return @"SPAN_KIND_CLIENT";
        case SPAN_KIND_PRODUCER:    return @"SPAN_KIND_PRODUCER";
        case SPAN_KIND_CONSUMER:    return @"SPAN_KIND_CONSUMER";
    }
}

static NSString * EncodeSpanId(SpanId const spanId) {
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x",
            spanId[0], spanId[1], spanId[2], spanId[3], spanId[4], spanId[5], spanId[6], spanId[7]];
}

static NSString * EncodeTraceId(TraceId const traceId) {
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            traceId[0], traceId[1], traceId[2], traceId[3], traceId[4], traceId[5], traceId[6], traceId[7],
            traceId[8], traceId[9], traceId[10], traceId[11], traceId[12], traceId[13], traceId[14], traceId[15]];
}

static NSString * EncodeCFAbsoluteTime(CFAbsoluteTime time) {
    auto nanos = (time + kCFAbsoluteTimeIntervalSince1970) * NSEC_PER_SEC;
    return [NSString stringWithFormat:@"%lld", (int64_t)nanos];
}

Span::Span(NSString *name, CFAbsoluteTime startTime, void (^onEnd)(const Span &span))
: name([name copy]), kind(SPAN_KIND_INTERNAL), startTime(startTime), onEnd(onEnd) {
    IdGenerator::generateSpanIdBytes(spanId);
    IdGenerator::generateTraceIdBytes(traceId);
}

NSDictionary *
Span::encode() const {
    // A Span represents a single operation performed by a single component of the system.
    auto span = @{
        // A unique identifier for a trace. All spans from the same trace share
        // the same `trace_id`. The ID is a 16-byte array. An ID with all zeroes
        // is considered invalid.
        //
        // This field is semantically required. Receiver should generate new
        // random trace_id if empty or invalid trace_id was received.
        //
        // This field is required.
        @"traceId": EncodeTraceId(traceId),
        
        // A unique identifier for a span within a trace, assigned when the span
        // is created. The ID is an 8-byte array. An ID with all zeroes is considered
        // invalid.
        //
        // This field is semantically required. Receiver should generate new
        // random span_id if empty or invalid span_id was received.
        //
        // This field is required.
        @"spanId": EncodeSpanId(spanId),
        
        // trace_state conveys information about request position in multiple distributed tracing graphs.
        // It is a trace_state in w3c-trace-context format: https://www.w3.org/TR/trace-context/#tracestate-header
        // See also https://github.com/w3c/distributed-tracing for more details about this field.
        // @"traceState":
        
        // The `span_id` of this span's parent span. If this is a root span, then this
        // field must be empty. The ID is an 8-byte array.
        // @"parentSpanId":
        
        // A description of the span's operation.
        //
        // For example, the name can be a qualified method name or a file name
        // and a line number where the operation is called. A best practice is to use
        // the same display name at the same call point in an application.
        // This makes it easier to correlate spans in different traces.
        //
        // This field is semantically required to be set to non-empty string.
        // Empty value is equivalent to an unknown span name.
        //
        // This field is required.
        @"name": name,
        
        // Distinguishes between spans generated in a particular context. For example,
        // two spans with the same name may be distinguished using `CLIENT` (caller)
        // and `SERVER` (callee) to identify queueing latency associated with the span.
        @"kind": EncodeSpanKind(kind),
        
        // start_time_unix_nano is the start time of the span. On the client side, this is the time
        // kept by the local machine where the span execution starts. On the server side, this
        // is the time when the server's application handler starts running.
        // Value is UNIX Epoch time in nanoseconds since 00:00:00 UTC on 1 January 1970.
        //
        // This field is semantically required and it is expected that end_time >= start_time.
        @"startTimeUnixNano": EncodeCFAbsoluteTime(startTime),
        
        // end_time_unix_nano is the end time of the span. On the client side, this is the time
        // kept by the local machine where the span execution ends. On the server side, this
        // is the time when the server application handler stops running.
        // Value is UNIX Epoch time in nanoseconds since 00:00:00 UTC on 1 January 1970.
        //
        // This field is semantically required and it is expected that end_time >= start_time.
        @"endTimeUnixNano": EncodeCFAbsoluteTime(endTime),
        
        // attributes is a collection of key/value pairs. Note, global attributes
        // like server name can be set using the resource API.
        // The OpenTelemetry API specification further restricts the allowed value types:
        // https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/common/README.md#attribute
        // Attribute keys MUST be unique (it is not allowed to have more than one
        // attribute with the same key).
        @"attributes": @[@{
            @"key": @"span_attribute",
            @"value": @{
                @"stringValue": @"something"
            }
        }],
    };
    return span;
}
