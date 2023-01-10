//
//  BugsnagPerformanceImpl.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 15.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "BugsnagPerformanceImpl.h"

#import "BSGInternalConfig.h"
#import "OtlpTraceEncoding.h"
#import "ResourceAttributes.h"
#import "Reachability.h"

using namespace bugsnag;

static double initialProbability = 1.0;

BugsnagPerformanceImpl::BugsnagPerformanceImpl() noexcept
: batch_(std::make_shared<Batch>())
, sampler_(std::make_shared<Sampler>(initialProbability))
, tracer_(sampler_, batch_)
{
}

bool BugsnagPerformanceImpl::start(BugsnagPerformanceConfiguration *configuration, NSError **error) noexcept {
    {
        std::lock_guard<std::mutex> guard(mutex_);
        if (started_) {
            return true;
        }
        started_ = true;
    }

    if (![configuration validate:error]) {
        return false;
    }

    /* Note: Be careful about initialization order!
     *
     * - uploader depends on resourceAttributes and sampler
     * - worker depends on uploader and sampler
     * - batch depends on worker
     * - tracer depends on sampler and batch
     * - Reachability depends on worker
     */

    __block auto blockThis = this;

    resourceAttributes_ = ResourceAttributes(configuration).get();

    sampler_->setFallbackProbability(configuration.samplingProbability);

    uploader_ = std::make_shared<OtlpUploader>(configuration.endpoint,
                                                   configuration.apiKey,
                                                   ^(double newProbability) {
        blockThis->onProbabilityChanged(newProbability);
    });

    worker_ = [[Worker alloc] initWithInitialTasks:buildInitialTasks()
                                    recurringTasks:buildRecurringTasks()
                                      workInterval:bsgp_performWorkInterval];
    [worker_ start];

    __block auto blockWorker = worker_;
    batch_->setBatchFullCallback(^{
        [blockWorker wake];
    });

    tracer_.start(configuration);

    Reachability::get().addCallback(^(Reachability::Connectivity connectivity) {
        switch (connectivity) {
            case Reachability::Cellular: case Reachability::Wifi:
                [blockWorker wake];
                break;
            case Reachability::Unknown: case Reachability::None:
                break;
        }
    });

    return true;
}

NSArray<Task> *BugsnagPerformanceImpl::buildInitialTasks() {
    __block auto blockThis = this;
    return @[
        ^bool() { return blockThis->sendInitialPValueRequestTask(); },
    ];
}

NSArray<Task> *BugsnagPerformanceImpl::buildRecurringTasks() {
    __block auto blockThis = this;
    return @[
        ^bool() { return blockThis->sendCurrentBatchAndRetriesTask(); },
    ];
}

bool BugsnagPerformanceImpl::sendInitialPValueRequestTask() {
    auto emptyPayload = [@"{\"resourceSpans\": []}" dataUsingEncoding:NSUTF8StringEncoding];
    auto emptyPackage = OtlpPackage(emptyPayload, @{});
    uploader_->upload(emptyPackage, nil);
    return true;
}

bool BugsnagPerformanceImpl::sendCurrentBatchAndRetriesTask() {
    if (retryQueue_.size() == 0) {
        return sendCurrentBatchTask();
    }

    // save retries before sending the current batch
    auto retries = std::move(retryQueue_);
    retryQueue_ = std::vector<std::unique_ptr<OtlpPackage>>();

    sendCurrentBatchTask();
    
    for (size_t i = 0; i < retries.size(); i++) {
        uploadPackage(std::move(retries[i]));
    }

    return true;
}

bool BugsnagPerformanceImpl::sendCurrentBatchTask() {
    auto spans = sampler_->sampled(batch_->drain());

    if (spans->size() > 0) {
        uploadPackage(buildPackage(*spans));
        return true;
    }
    return false;
}

void BugsnagPerformanceImpl::onProbabilityChanged(double newProbability) noexcept {
    sampler_->setProbability(newProbability);
}

void BugsnagPerformanceImpl::uploadPackage(std::unique_ptr<OtlpPackage> package) noexcept {
    if (package == nullptr) {
        return;
    }
    
    __block auto blockThis = this;
    __block std::unique_ptr<OtlpPackage> blockPackage = std::move(package);

    uploader_->upload(*blockPackage, ^(UploadResult result) {
        switch (result) {
            case UploadResult::SUCCESSFUL:
                break;
            case UploadResult::FAILED_CAN_RETRY:
                blockThis->queueRetry(std::move(blockPackage));
                break;
            case UploadResult::FAILED_CANNOT_RETRY:
                // We can't do anything with it, so throw it out.
                break;
        }
    });
}

void BugsnagPerformanceImpl::queueRetry(std::unique_ptr<OtlpPackage> package) noexcept {
    retryQueue_.push_back(std::move(package));
}

std::unique_ptr<OtlpPackage> BugsnagPerformanceImpl::buildPackage(const std::vector<std::unique_ptr<SpanData>> &spans) const noexcept {
    return OtlpTraceEncoding::buildUploadPackage(spans, resourceAttributes_);
}
