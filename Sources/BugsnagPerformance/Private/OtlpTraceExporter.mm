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
    uploadPackage(buildPackage(spans));
}

void OtlpTraceExporter::uploadPackage(std::unique_ptr<OtlpPackage> package) noexcept {
    if (package == nullptr) {
        return;
    }
    __block std::unique_ptr<OtlpPackage> blockPackage = std::move(package);

    uploader_->upload(*blockPackage, ^(__unused UploadResult result) {
        switch (result) {
            case UploadResult::SUCCESSFUL:
                sendNextRetry();
                break;
            case UploadResult::FAILED_CAN_RETRY:
                retryQueue_.push(std::move(blockPackage));
                break;
            case UploadResult::FAILED_CANNOT_RETRY:
                // We can't do anything with it, so throw it out.
                break;
        }
    });
}

void OtlpTraceExporter::sendNextRetry(void) noexcept {
    auto retry = retryQueue_.pop();
    uploadPackage(std::move(retry));
}

void
OtlpTraceExporter::notifyConnectivityReestablished() noexcept {
    sendNextRetry();
}

std::unique_ptr<OtlpPackage> OtlpTraceExporter::buildPackage(const std::vector<std::unique_ptr<SpanData>> &spans) const noexcept {
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
