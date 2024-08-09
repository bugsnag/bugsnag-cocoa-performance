//
//  Batch.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 15.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#pragma once

#import "PhasedStartup.h"
#import "BugsnagPerformanceConfiguration+Private.h"
#import "SpanData.h"
#import "PhasedStartup.h"
#import "Utils.h"

#import <memory>
#import <mutex>
#import <vector>

namespace bugsnag {

/**
 * Holds the next batch of spans that will be sent together to the backend.
 */
class Batch: public PhasedStartup {
public:
    Batch() noexcept
    : spans_(std::make_unique<std::vector<std::shared_ptr<SpanData>>>())
    , onBatchFull(^(){})
    {}

    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *config) noexcept {
        autoTriggerExportOnBatchSize_ = config.internal.autoTriggerExportOnBatchSize;
    }
    void preStartSetup() noexcept {}
    void start() noexcept {}

    /**
     * Add a span to this batch. If the batch size exceeds the maximum, call the "batch full" callback.
     **/
    void add(std::shared_ptr<SpanData> span) noexcept {
        bool isFull = false;
        {
            std::lock_guard<std::mutex> guard(mutex_);
            BSGLogDebug(@"Batch:add(%@): Batch size will be %zu", span->name, spans_->size()+1);
            spans_->push_back(span);
            isFull = spans_->size() >= autoTriggerExportOnBatchSize_;
            if (isFull) {
                drainIsAllowed_ = true;
            }
        }
        if (isFull) {
            BSGLogTrace(@"Batch:add: batch is full");
            onBatchFull();
        }
    }

    void removeSpan(TraceId traceId, SpanId spanId) noexcept {
        BSGLogDebug(@"Batch:removeSpan(%llx%llx, %llx)", traceId.hi, traceId.lo, spanId);
        std::lock_guard<std::mutex> guard(mutex_);

        if (spans_->empty()) {
            BSGLogDebug(@"Batch:removeSpan(%llx%llx, %llx): Batch is empty", traceId.hi, traceId.lo, spanId);
            return;
        }
        auto found = std::find_if(spans_->begin(),
                     spans_->end(),
                     [&spanId, &traceId](const std::shared_ptr<SpanData> &o) {
            return o->spanId == spanId && o->traceId.value == traceId.value;
        });
        if (found == spans_->end()) {
            BSGLogDebug(@"Batch:removeSpan(%llx%llx, %llx): Span not found", traceId.hi, traceId.lo, spanId);
            return;
        }

        spans_->erase(found);

        for (auto span: *spans_) {
            if (span->parentId == spanId && span->traceId.value == traceId.value) {
                span->parentId = 0;
            }
        }
        BSGLogDebug(@"Batch:removeSpan(%llx%llx, %llx): Span %@ removed. Batch size is now %zu",
                    traceId.hi, traceId.lo, spanId, (*found)->name, spans_->size());
    }

    /**
     * Drain this batch of all of its spans, if draining is allowed.
     * Returns the drained spans, or an empty vector if draining is not allowed.
     */
    std::unique_ptr<std::vector<std::shared_ptr<SpanData>>> drain(bool force) noexcept {
        BSGLogDebug(@"Batch:drain(force:%s)", force ? "yes" : "no");
        std::lock_guard<std::mutex> guard(mutex_);
        if (!drainIsAllowed_ && !force) {
            BSGLogDebug(@"Batch:drain: not currently allowed");
            return std::make_unique<std::vector<std::shared_ptr<SpanData>>>();
        }
        drainIsAllowed_ = false;

        auto batch = std::move(spans_);
        spans_ = std::make_unique<std::vector<std::shared_ptr<SpanData>>>();
        BSGLogDebug(@"Batch:drain: draining %zu spans", batch->size());
        return batch;
    }

    /**
     * Allows this batch's spans to be drained once.
     */
    void allowDrain() noexcept {
        BSGLogDebug(@"Batch:allowDrain()");
        std::lock_guard<std::mutex> guard(mutex_);
        drainIsAllowed_ = true;
    }

    void setBatchFullCallback(void (^batchFullCallback)()) {
        onBatchFull = batchFullCallback;
    }

    size_t count() noexcept {
        return spans_->size();
    }

private:
    void (^onBatchFull)(){nullptr};
    bool drainIsAllowed_{false};
    uint64_t autoTriggerExportOnBatchSize_{0};
    std::mutex mutex_;
    std::unique_ptr<std::vector<std::shared_ptr<SpanData>>> spans_;
};
}
