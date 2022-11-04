//
//  OtlpTraceExporter.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 05/10/2022.
//

#import <Foundation/Foundation.h>

#import "SpanExporter.h"
#import "OtlpPackage.h"
#import "BugsnagPerformanceUploader.h"

namespace bugsnag {
class OtlpTraceExporter: public SpanExporter {
public:
    OtlpTraceExporter(NSURL *endpoint, NSDictionary *resourceAttributes, NewProbabilityCallback newProbabilityCallback) noexcept
    : resourceAttributes_(resourceAttributes)
    , uploader_(endpoint, newProbabilityCallback)
    {}
    
    void exportSpans(std::vector<std::unique_ptr<SpanData>> spans) noexcept override;
    
private:
    NSDictionary *resourceAttributes_;
    BugsnagPerformanceUploader uploader_;

    std::unique_ptr<OtlpPackage> buildPackage(std::vector<std::unique_ptr<SpanData>> &spans);
};
}
