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
    , resourceAttributes_(resourceAttributes)
    , responseObserver_(nil)
    {}
    
    void exportSpans(std::vector<std::unique_ptr<SpanData>> spans) noexcept override;
    
    void setResponseObserver(void (^ observer)(NSHTTPURLResponse *response)) noexcept override {
        responseObserver_ = observer;
    }
    
private:
    NSURL *endpoint_;
    NSDictionary *resourceAttributes_;
    void (^ responseObserver_)(NSHTTPURLResponse *response);
};
}
