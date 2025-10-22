//
//  UploadModule.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 17/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "UploadModule.h"

using namespace bugsnag;

#pragma mark PhasedStartup

void
UploadModule::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    traceEncoding_->earlyConfigure(config);
    retryQueue_->earlyConfigure(config);
    uploader_->earlyConfigure(config);
}

void
UploadModule::earlySetup() noexcept {
    traceEncoding_->earlySetup();
    retryQueue_->earlySetup();
    uploader_->earlySetup();
}

void
UploadModule::configure(BugsnagPerformanceConfiguration *config) noexcept {
    traceEncoding_->configure(config);
    retryQueue_->configure(config);
    uploader_->configure(config);
}

void
UploadModule::preStartSetup() noexcept {
    traceEncoding_->preStartSetup();
    retryQueue_->preStartSetup();
    uploader_->preStartSetup();
}

void
UploadModule::start() noexcept {
    traceEncoding_->start();
    retryQueue_->start();
    uploader_->start();
}

#pragma mark Module

void
UploadModule::setUp() noexcept {
    retryQueue_ = std::make_shared<RetryQueue>([persistence_->bugsnagPerformanceDir() stringByAppendingPathComponent:@"retry-queue"]);
    traceEncoding_ = std::make_shared<OtlpTraceEncoding>();
    uploader_ = std::make_shared<OtlpUploader>();
}
