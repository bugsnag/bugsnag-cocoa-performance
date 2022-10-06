//
//  Span.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import <Foundation/Foundation.h>

#import "SpanData.h"

#import <memory>
#import <vector>

namespace bugsnag {
// https://opentelemetry.io/docs/reference/specification/trace/api/#span
class Span {
public:
    Span(std::unique_ptr<SpanData> data,
         std::shared_ptr<class SpanProcessor> spanProcessor) noexcept;
    
    Span(const Span&) = delete;
    
    void end(CFAbsoluteTime time) noexcept;
    
private:
    std::unique_ptr<SpanData> data_;
    std::shared_ptr<class SpanProcessor> processor_;
};
}
