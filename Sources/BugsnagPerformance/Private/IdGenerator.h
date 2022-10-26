//
//  IdGenerator.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <array>
#import <stdlib.h>

namespace bugsnag {
// https://opentelemetry.io/docs/reference/specification/trace/api/#spancontext

using SpanId = std::array<uint64_t, 1>;

static_assert(sizeof(SpanId) == 8,
              "A valid span identifier is an 8-byte array with at least one non-zero byte.");

using TraceId = std::array<uint64_t, 2>;

static_assert(sizeof(TraceId) == 16,
              "A valid trace identifier is a 16-byte array with at least one non-zero byte.");

// https://opentelemetry.io/docs/reference/specification/trace/sdk/#id-generators
class IdGenerator {
public:
    static SpanId generateSpanIdBytes() noexcept {
        return random<SpanId>();
    }
    
    static TraceId generateTraceIdBytes() noexcept {
        return random<TraceId>();
    }
    
private:
    template<typename T> static T random() noexcept {
        T result;
        arc4random_buf(std::begin(result), sizeof result);
        return result;
    }
};
}
