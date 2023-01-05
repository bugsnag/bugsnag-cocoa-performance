//
//  BatchSpanProcessor.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 05/10/2022.
//

#import "BatchSpanProcessor.h"

#import "Sampler.h"
#import "BSGInternalConfig.h"
#import <time.h>


using namespace bugsnag;


BatchSpanProcessor::BatchSpanProcessor(std::shared_ptr<class Sampler> sampler) noexcept
: sampler_(sampler)
, timerCallbackValidityMarker([NSMutableData dataWithLength:0])
{
    CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(),
                                    this,
                                    notificationCallback,
                                    CFSTR("UIApplicationDidEnterBackgroundNotification"),
                                    nullptr,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
}

BatchSpanProcessor::~BatchSpanProcessor() noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetLocalCenter(),
                                       this,
                                       CFSTR("UIApplicationDidEnterBackgroundNotification"),
                                       nullptr);
    stopTimer();
}

void
BatchSpanProcessor::notificationCallback(__unused CFNotificationCenterRef center,
                                         __unused void *observer,
                                         __unused CFNotificationName name,
                                         __unused const void *object,
                                         __unused CFDictionaryRef userInfo) noexcept {
    auto this_ = (BatchSpanProcessor *)observer;
    if (this_ != nullptr) {
        std::lock_guard<std::mutex> guard(this_->mutex_);
        this_->exportSpans();
    }
}

void
BatchSpanProcessor::onEnd(std::unique_ptr<SpanData> span) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    if (!shouldSample(span)) {
        // This span should not be sampled; discard.
        return;
    }
    spans_.push_back(std::move(span));
    if (!tryExportSpans()) {
        startTimer();
    }
}

void
BatchSpanProcessor::setSpanExporter(std::shared_ptr<SpanExporter> exporter) noexcept {
    std::lock_guard<std::mutex> guard(mutex_);
    exporter_ = exporter;
    exportSpans();
}

bool
BatchSpanProcessor::shouldSample(std::unique_ptr<SpanData> &span) noexcept {
    auto decision = sampler_->shouldSample(span->traceId); 
    if (!decision.isSampled) {
        return false;
    }
    span->updateSamplingProbability(decision.sampledProbability);
    return true;
}

bool
BatchSpanProcessor::tryExportSpans() noexcept {
    stopTimer();

    // Try all conditions to automatically export the current batch

    if (spans_.size() >= bsgp_autoTriggerExportOnBatchSize) {
        exportSpans();
        return true;
    }

    return false;
}

void
BatchSpanProcessor::exportSpans() noexcept {
    stopTimer();
    if (!exporter_) {
        return;
    }
    // Resample in case probability changed
    std::vector<std::unique_ptr<SpanData>> sampled;
    for (auto &span: spans_) {
        if (shouldSample(span)) {
            sampled.push_back(std::move(span));
        }
    }
    spans_.clear();
    if (sampled.empty()) {
        return;
    }
    exporter_->exportSpans(std::move(sampled));
    NSCParameterAssert(spans_.empty());
}

void
BatchSpanProcessor::startTimer() noexcept {
    /* The dispatched callback's block can outlive BatchSpanProcessor, resulting in a
     * crash when the block tries to call methods on it. Normally you get around this by
     * keeping a __weak copy of the caller object, but ARC semantics don't work for a C++
     * caller, and you can't count on destructor timing.
     *
     * As a workaround, we create a mutable object whose sole purpose is to signal the
     * callback block. We can't rely on __weak alone to clear a sentinel's pointer to nil
     * because BatchSpanProcessor could be deallocated before the current autorelease pool
     * ends.
     *
     * I'm using NSMutableData as a signaling mechanism, using a length of 0 to mean
     * "do not execute the callback block" (we also get 0 if called on a nil object, which
     * will happen after BatchSpanProcessor drops its reference due to the __weak modifier).
     * The __weak modifier ensures that ARC handles the lifetime properly.
     *
     * To cancel an outstanding operation, set the NSMutableData object's length to 0
     * and then create a new one to break the link to the dispatch queue callback.
     * See stopTimer()
     */
    [timerCallbackValidityMarker setLength:1];
    __weak auto validityMarker = timerCallbackValidityMarker;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, int64_t(bsgp_autoTriggerExportOnTimeDuration)),
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^(void){
#pragma GCC diagnostic ignored "-Warc-repeated-use-of-weak"
        // We want repeated use of weak here to catch race conditions.
        if (validityMarker.length > 0) {
            std::lock_guard<std::mutex> guard(this->mutex_);
            if (validityMarker.length > 0) {
                this->exportSpans();
            }
        }
    });
}

void
BatchSpanProcessor::stopTimer() noexcept {
    /* Set timerCallbackValidityMarker's length to 0 as a signal to any outstanding
     * callbacks that they should not execute.
     * Then, create a new NSMutableData object to break the link to any dispatch queue callback.
     * See startTimer()
     */
    [timerCallbackValidityMarker setLength:0];
    timerCallbackValidityMarker = [NSMutableData dataWithLength:0];
};
