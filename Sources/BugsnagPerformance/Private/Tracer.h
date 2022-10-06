//
//  Tracer.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <Foundation/Foundation.h>
#import <memory>

namespace bugsnag {
// https://opentelemetry.io/docs/reference/specification/trace/api/#tracer
class Tracer {
public:
    Tracer() noexcept;
    
    void start(NSURL *endpoint) noexcept;
    
    std::unique_ptr<class Span> startSpan(NSString *name, CFAbsoluteTime startTime) noexcept;
    
private:
    std::shared_ptr<class SpanProcessor> spanProcessor_;
};
}
