//
//  OtlpTraceExporter.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 05/10/2022.
//

#import "OtlpTraceExporter.h"

#import "OtlpTraceEncoding.h"

using namespace bugsnag;

void
OtlpTraceExporter::exportSpans(std::vector<std::unique_ptr<SpanData>> spans) noexcept {
    const auto package = buildPackage(spans);
    if (package == nullptr) {
        return;
    }

    uploader_.upload(*package, ^(__unused UploadResult result) {
        // Nothing to do yet
    });
}

std::unique_ptr<OtlpPackage> OtlpTraceExporter::buildPackage(std::vector<std::unique_ptr<SpanData>> &spans) {
    auto encodedSpans = OtlpTraceEncoding::encode(spans, resourceAttributes_);
    
    NSError *error = nil;
    auto payload = [NSJSONSerialization dataWithJSONObject:encodedSpans options:0 error:&error];
    if (!payload) {
        NSCAssert(NO, @"%@", error);
        return nullptr;
    }

    auto headers = @{
        @"Content-Type": @"application/json",
    };
    
    return std::make_unique<OtlpPackage>(payload, headers);
}
