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
#import "BugsnagPerformanceSpan+Private.h"
#import "PhasedStartup.h"
#import "Utils.h"

#import <memory>
#import <mutex>
#import <vector>

namespace bugsnag {

const int normalBatchSize = 100;

/**
 * Holds the next batch of spans that will be sent together to the backend.
 */
class Batch: public PhasedStartup {
public:
    Batch() noexcept
    : spans_([NSMutableArray arrayWithCapacity:normalBatchSize])
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
    void add(BugsnagPerformanceSpan *span) noexcept {
        bool isFull = false;
        {
            std::lock_guard<std::mutex> guard(mutex_);
            BSGLogDebug(@"Batch:add(%@): Batch size will be %zu", span.name, spans_.count+1);
            [spans_ addObject:span];
            isFull = spans_.count >= autoTriggerExportOnBatchSize_;
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

        if (spans_.count == 0) {
            BSGLogDebug(@"Batch:removeSpan(%llx%llx, %llx): Batch is empty", traceId.hi, traceId.lo, spanId);
            return;
        }

        BugsnagPerformanceSpan *found = nil;
        size_t index = 0;
        for(; index < spans_.count; index++) {
            BugsnagPerformanceSpan *potential = spans_[index];
            if (potential.spanId == spanId && potential.traceId.value == traceId.value) {
                found = potential;
            }
        }

        if (found == nil) {
            BSGLogDebug(@"Batch:removeSpan(%llx%llx, %llx): Span not found", traceId.hi, traceId.lo, spanId);
            return;
        }

        [spans_ removeObject:found];
//        [spans_ removeObjectAtIndex:index];

        for (BugsnagPerformanceSpan *span in spans_) {
            if (span.parentId == spanId && span.traceId.value == traceId.value) {
                span.parentId = 0;
            }
        }
        BSGLogDebug(@"Batch:removeSpan(%llx%llx, %llx): Span %@ removed. Batch size is now %zu",
                    traceId.hi, traceId.lo, spanId, found.name, spans_.count);
    }

    /**
     * Drain this batch of all of its spans, if draining is allowed.
     * Returns the drained spans, or an empty vector if draining is not allowed.
     */
    NSMutableArray<BugsnagPerformanceSpan *> *drain(bool force) noexcept {
        BSGLogDebug(@"Batch:drain(force:%s)", force ? "yes" : "no");
        std::lock_guard<std::mutex> guard(mutex_);
        if (!drainIsAllowed_ && !force) {
            BSGLogDebug(@"Batch:drain: not currently allowed");
            return [NSMutableArray array];
        }
        drainIsAllowed_ = false;

        auto batch = spans_;
        spans_ = [NSMutableArray arrayWithCapacity:normalBatchSize];
        BSGLogDebug(@"Batch:drain: draining %zu spans", batch.count);
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
        return spans_.count;
    }

private:
    void (^onBatchFull)(){nullptr};
    bool drainIsAllowed_{false};
    uint64_t autoTriggerExportOnBatchSize_{0};
    std::mutex mutex_;
    NSMutableArray<BugsnagPerformanceSpan *> *spans_;
};
}
