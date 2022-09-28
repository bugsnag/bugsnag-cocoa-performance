//
//  Tracer.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "Span.h"

#import <memory>

namespace bugsnag {
// https://opentelemetry.io/docs/reference/specification/trace/api/#tracer
class Tracer {
public:
    Tracer(NSURL *endpoint) noexcept;
    
    std::shared_ptr<Span> startSpan(NSString *name, CFAbsoluteTime startTime) noexcept;
    
private:
    void onEnd(const Span &span) noexcept;
    
    NSDictionary *resourceAttributes;
    NSURL *endpoint;
};
}
