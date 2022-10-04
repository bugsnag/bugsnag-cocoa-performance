//
//  IdGenerator.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

namespace bugsnag {
// https://opentelemetry.io/docs/reference/specification/trace/api/#spancontext

// A valid span identifier is an 8-byte array with at least one non-zero byte.
typedef uint8_t SpanId[8];

// A valid trace identifier is a 16-byte array with at least one non-zero byte.
typedef uint8_t TraceId[16];

// https://opentelemetry.io/docs/reference/specification/trace/sdk/#id-generators
class IdGenerator {
public:
    static void generateSpanIdBytes(SpanId spanId) noexcept {
        arc4random_buf(spanId, sizeof(SpanId));
    }
    
    static void generateTraceIdBytes(TraceId traceId) noexcept {
        arc4random_buf(traceId, sizeof(TraceId));
    }
};
}
