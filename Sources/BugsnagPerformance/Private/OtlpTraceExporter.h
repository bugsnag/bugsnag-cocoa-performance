//
//  OtlpTraceExporter.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 05/10/2022.
//

#import <Foundation/Foundation.h>

#import "SpanExporter.h"

namespace bugsnag {
class OtlpTraceExporter: public SpanExporter {
public:
    OtlpTraceExporter(NSURL *endpoint, NSDictionary *resourceAttributes) noexcept
    : endpoint_(endpoint)
    , resourceAttributes_(resourceAttributes) {}
    
    void exportSpans(std::vector<SpanPtr> spans) noexcept override;
    
private:
    NSURL *endpoint_;
    NSDictionary *resourceAttributes_;
};
}
