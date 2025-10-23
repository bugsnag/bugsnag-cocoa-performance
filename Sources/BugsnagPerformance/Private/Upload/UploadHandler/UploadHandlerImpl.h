//
//  UploadHandlerImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "UploadHandler.h"
#import "../../Core/PhasedStartup.h"
#import "../Otlp/OtlpTraceEncoding.h"
#import "../Otlp/Uploader.h"
#import "../RetryQueue.h"
#import "../../Core/Attributes/ResourceAttributes.h"
#import <memory>

namespace bugsnag {
class UploadHandlerImpl: public UploadHandler, public PhasedStartup {
public:
    UploadHandlerImpl(std::shared_ptr<OtlpTraceEncoding> traceEncoding,
                      std::shared_ptr<Uploader> uploader,
                      std::shared_ptr<RetryQueue> retryQueue,
                      std::shared_ptr<ResourceAttributes> resourceAttributes) noexcept
        : traceEncoding_(traceEncoding)
        , uploader_(uploader)
        , retryQueue_(retryQueue)
        , resourceAttributes_(resourceAttributes) {
    }
    
    ~UploadHandlerImpl() {};
    
    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept {}
    void start() noexcept {}
    
    void uploadPValueRequest(TaskCompletion completion) noexcept;
    void uploadSpans(NSArray<BugsnagPerformanceSpan *> *spans, TaskCompletion completion) noexcept;
    void sendRetries(TaskCompletion completion) noexcept;
    
private:
    BugsnagPerformanceConfiguration *configuration_;
    std::shared_ptr<OtlpTraceEncoding> traceEncoding_;
    std::shared_ptr<Uploader> uploader_;
    std::shared_ptr<RetryQueue> retryQueue_;
    std::shared_ptr<ResourceAttributes> resourceAttributes_;
    
    CFAbsoluteTime probabilityExpiry_{0};
    CFAbsoluteTime pausePValueRequestsUntil_{0};
    CFTimeInterval probabilityValueExpiresAfterSeconds_{0};
    CFTimeInterval probabilityRequestsPauseForSeconds_{0};
    uint64_t maxPackageContentLength_{1000000};

    void uploadPackage(std::unique_ptr<OtlpPackage> package, bool isRetry, TaskCompletion completion) noexcept;
};
}
