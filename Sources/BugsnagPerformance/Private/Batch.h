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
#import "SpanData.h"
#import "PhasedStartup.h"
#import "Utils.h"

#import <memory>
#import <mutex>
#import <vector>

namespace bugsnag {

#define INITIAL_BATCH_CAPACITY 100

/**
 * Holds the next batch of spans that will be sent together to the backend.
 */
class Batch: public PhasedStartup {
public:
    Batch() noexcept
    : spans_([NSMutableDictionary dictionaryWithCapacity:INITIAL_BATCH_CAPACITY])
    , onBatchFull(^(){})
    {}

    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *config) noexcept {
        autoTriggerExportOnBatchSize_ = config.internal.autoTriggerExportOnBatchSize;
    }
    void start() noexcept {}

    /**
     * Add a span to this batch. If the batch size exceeds the maximum, call the "batch full" callback.
     **/
    void add(BugsnagPerformanceSpan *span) noexcept {
        BSGLogDebug(@"Batch:add(%@)", span.name);
        bool isFull = false;
        {
            std::lock_guard<std::mutex> guard(mutex_);
            spans_[makeSpanKey(span.traceId, span.spanId)] = span;
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
        [spans_ removeObjectForKey:makeSpanKey(traceId, spanId)];

        for (BugsnagPerformanceSpan *span: [spans_ allValues]) {
            if (span.parentId == spanId && span.traceId.value == traceId.value) {
                span.parentId = 0;
            }
        }
    }

    /**
     * Drain this batch of all of its spans, if draining is allowed.
     * Returns the drained spans, or an empty vector if draining is not allowed.
     */
    NSArray *drain(bool force) noexcept {
        BSGLogDebug(@"Batch:drain(force:%s)", force ? "yes" : "no");
        std::lock_guard<std::mutex> guard(mutex_);
        if (!drainIsAllowed_ && !force) {
            BSGLogDebug(@"Batch:drain: not currently allowed");
            return nil;
        }
        drainIsAllowed_ = false;

        NSMutableArray *batch = [NSMutableArray arrayWithCapacity:spans_.count];
        for(BugsnagPerformanceSpan *span: [spans_ allValues]) {
            [batch addObject:span];
        }
        [spans_ removeAllObjects];
        BSGLogDebug(@"Batch:drain: drained %zu spans", batch.count);
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
    NSMutableDictionary *spans_;
    
    static NSString *makeSpanKey(TraceId traceId, SpanId spanId) {
        // Go from least significant to most significant since spanId will have higher variability.
        return [NSString stringWithFormat:@"%llu.%llu.%llu", spanId, traceId.lo, traceId.hi];
    }
};
}
