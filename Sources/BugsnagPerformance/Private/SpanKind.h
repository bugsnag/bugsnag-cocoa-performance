//
//  SpanKind.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#pragma once

namespace bugsnag {
enum SpanKind {
    // Unspecified. Do NOT use as default.
    // Implementations MAY assume SpanKind to be INTERNAL when receiving UNSPECIFIED.
    SPAN_KIND_UNSPECIFIED = 0,
    
    // Indicates that the span represents an internal operation within an application,
    // as opposed to an operation happening at the boundaries. Default value.
    SPAN_KIND_INTERNAL = 1,
    
    // Indicates that the span covers server-side handling of an RPC or other
    // remote network request.
    SPAN_KIND_SERVER = 2,
    
    // Indicates that the span describes a request to some remote service.
    SPAN_KIND_CLIENT = 3,
    
    // Indicates that the span describes a producer sending a message to a broker.
    // Unlike CLIENT and SERVER, there is often no direct critical path latency relationship
    // between producer and consumer spans. A PRODUCER span ends when the message was accepted
    // by the broker while the logical processing of the message might span a much longer time.
    SPAN_KIND_PRODUCER = 4,
    
    // Indicates that the span describes consumer receiving a message from a broker.
    // Like the PRODUCER kind, there is often no direct critical path latency relationship
    // between producer and consumer spans.
    SPAN_KIND_CONSUMER = 5,
};
}
