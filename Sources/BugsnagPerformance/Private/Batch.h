//
//  Batch.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 15.12.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#pragma once

#import "BSGInternalConfig.h"
#import "SpanData.h"

#import <memory>
#import <mutex>
#import <vector>

namespace bugsnag {

/**
 * Holds the next batch of spans that will be sent together to the backend.
 */
class Batch {
public:
    Batch() noexcept
    : spans_(std::make_unique<std::vector<std::shared_ptr<SpanData>>>())
    , onBatchFull(^(){})
    {}

    /**
     * Add a span to this batch. If the batch size exceeds the maximum, call the "batch full" callback.
     **/
    void add(std::shared_ptr<SpanData> span) noexcept {
        bool isFull = false;
        {
            std::lock_guard<std::mutex> guard(mutex_);
            spans_->push_back(span);
            isFull = spans_->size() >= bsgp_autoTriggerExportOnBatchSize;
            if (isFull) {
                drainIsAllowed_ = true;
            }
        }
        if (isFull) {
            onBatchFull();
        }
    }

    void removeSpan(TraceId traceId, SpanId spanId) noexcept {
        std::lock_guard<std::mutex> guard(mutex_);

        if (spans_->empty()) {
            return;
        }
        auto found = std::find_if(spans_->begin(),
                     spans_->end(),
                     [&spanId, &traceId](const std::shared_ptr<SpanData> &o) {
            return o->spanId == spanId && o->traceId.value == traceId.value;
        });
        if (found == spans_->end()) {
            return;
        }

        spans_->erase(found);

        for (auto span: *spans_) {
            if (span->parentId == spanId && span->traceId.value == traceId.value) {
                span->parentId = 0;
            }
        }
    }

    /**
     * Drain this batch of all of its spans, if draining is allowed.
     * Returns the drained spans, or an empty vector if draining is not allowed.
     */
    std::unique_ptr<std::vector<std::shared_ptr<SpanData>>> drain() noexcept {
        std::lock_guard<std::mutex> guard(mutex_);
        if (!drainIsAllowed_) {
            return std::make_unique<std::vector<std::shared_ptr<SpanData>>>();
        }
        drainIsAllowed_ = false;

        auto batch = std::move(spans_);
        spans_ = std::make_unique<std::vector<std::shared_ptr<SpanData>>>();
        return batch;
    }

    /**
     * Allows this batch's spans to be drained once.
     */
    void allowDrain() noexcept {
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
    std::mutex mutex_;
    std::unique_ptr<std::vector<std::shared_ptr<SpanData>>> spans_;
};
}
