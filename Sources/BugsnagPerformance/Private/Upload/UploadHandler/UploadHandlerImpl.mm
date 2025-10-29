//
//  UploadHandlerImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 23/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "UploadHandlerImpl.h"
#import "../../Core/Configuration/BugsnagPerformanceConfiguration+Private.h"
#import "../Otlp/Uploader.h"
#import "../Otlp/OtlpPackage.h"
#import "../RetryQueue.h"

using namespace bugsnag;

#pragma mark PhasedStartup

void
UploadHandlerImpl::configure(BugsnagPerformanceConfiguration *config) noexcept {
    configuration_ = config;
    probabilityValueExpiresAfterSeconds_ = config.internal.probabilityValueExpiresAfterSeconds;
    probabilityRequestsPauseForSeconds_ = config.internal.probabilityRequestsPauseForSeconds;
    maxPackageContentLength_ = config.internal.maxPackageContentLength;
}

#pragma mark Public

void
UploadHandlerImpl::uploadPValueRequest(TaskCompletion completion) noexcept {
    if (!configuration_.shouldSendReports || configuration_.samplingProbability != nil) {
        completion(false);
        return;
    }
    auto currentTime = CFAbsoluteTimeGetCurrent();
    if (currentTime > pausePValueRequestsUntil_ && currentTime > probabilityExpiry_) {
        // Pause P-value requests so that we don't flood the server on every span start
        pausePValueRequestsUntil_ = currentTime + probabilityRequestsPauseForSeconds_;
        uploader_->upload(*traceEncoding_->buildPValueRequestPackage(), ^(UploadResult) {
            completion(false);
        });
    } else {
        completion(false);
    }
}

void
UploadHandlerImpl::uploadSpans(NSArray<BugsnagPerformanceSpan *> *spans, TaskCompletion completion) noexcept {
    if (spans.count == 0) {
        completion(false);
    }
    bool includeSamplingHeader = configuration_ == nil || configuration_.samplingProbability == nil;
    uploadPackage(traceEncoding_->buildUploadPackage(spans, resourceAttributes_->get(), includeSamplingHeader), false, completion);
}

void
UploadHandlerImpl::sendRetries(TaskCompletion completion) noexcept {
    retryQueue_->sweep();

    auto retries = retryQueue_->list();
    if (retries.size() == 0) {
        completion(false);
        return;
    }

    for (auto &&timestamp: retries) {
        __block auto retry = retryQueue_->get(timestamp);
        if (retry != nullptr) {
            auto work = ^(TaskCompletion retryCompletion) {
                uploadPackage(std::move(retry), true, retryCompletion);
            };
            auto task = std::make_shared<AsyncToSyncTask>(work);
            task->executeSync();
        }
    }

    // Retries never count as work, otherwise we'd loop endlessly on a network outage.
    completion(false);
}

#pragma mark Private

void
UploadHandlerImpl::uploadPackage(std::unique_ptr<OtlpPackage> package,
                                 bool isRetry,
                                 TaskCompletion completion) noexcept {
    if (!configuration_.shouldSendReports || package == nullptr) {
        completion(false);
        return;
    }

    __block auto blockThis = this;
    __block std::unique_ptr<OtlpPackage> blockPackage = std::move(package);

    uploader_->upload(*blockPackage, ^(UploadResult result) {
        switch (result) {
            case UploadResult::SUCCESSFUL:
                if (isRetry) {
                    blockThis->retryQueue_->remove(blockPackage->timestamp);
                }
                break;
            case UploadResult::FAILED_CAN_RETRY:
                if (!isRetry && blockPackage->uncompressedContentLength() <= maxPackageContentLength_) {
                    blockThis->retryQueue_->add(*blockPackage);
                }
                break;
            case UploadResult::FAILED_CANNOT_RETRY:
                // We can't do anything with it, so throw it out.
                if (isRetry) {
                    blockThis->retryQueue_->remove(blockPackage->timestamp);
                }
                break;
        }
        blockThis->probabilityExpiry_ = CFAbsoluteTimeGetCurrent() + probabilityValueExpiresAfterSeconds_;
        completion(true);
    });
}
