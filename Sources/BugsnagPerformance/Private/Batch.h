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
    : spans_(std::make_unique<std::vector<std::unique_ptr<SpanData>>>())
    , onBatchFull(^(){})
    {}

    /**
     * Add a span to this batch. If the batch size exceeds the maximum, call the "batch full" callback.
     **/
    void add(std::unique_ptr<SpanData> span) noexcept {
        bool isFull = false;
        {
            std::lock_guard<std::mutex> guard(mutex_);
            spans_->push_back(std::move(span));
            isFull = spans_->size() >= bsgp_autoTriggerExportOnBatchSize;
            if (isFull) {
                drainIsAllowed_ = true;
            }
        }
        if (isFull) {
            onBatchFull();
        }
    }

    /**
     * Drain this batch of all of its spans, if draining is allowed.
     * Returns the drained spans, or an empty vector if draining is not allowed.
     */
    std::unique_ptr<std::vector<std::unique_ptr<SpanData>>> drain() noexcept {
        std::lock_guard<std::mutex> guard(mutex_);
        if (!drainIsAllowed_) {
            return std::make_unique<std::vector<std::unique_ptr<SpanData>>>();
        }
        drainIsAllowed_ = false;

        auto batch = std::move(spans_);
        spans_ = std::make_unique<std::vector<std::unique_ptr<SpanData>>>();
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

private:
    void (^onBatchFull)();
    bool drainIsAllowed_;
    std::mutex mutex_;
    std::unique_ptr<std::vector<std::unique_ptr<SpanData>>> spans_;
};
}
