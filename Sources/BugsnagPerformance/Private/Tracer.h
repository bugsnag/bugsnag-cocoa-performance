//
//  Tracer.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#pragma once

#import <BugsnagPerformance/BugsnagPerformanceConfiguration.h>
#import <BugsnagPerformance/BugsnagPerformanceViewType.h>
#import "Sampler.h"
#import "Batch.h"
#import "SpanOptions.h"
#import "PhasedStartup.h"
#import "SpanAttributesProvider.h"
#import "SpanStackingHandler.h"
#import "WeakSpansList.h"

#import <memory>

namespace bugsnag {
// https://opentelemetry.io/docs/reference/specification/trace/api/#tracer

/**
 * Tracer starts all spans, then samples them and routes them to the batch when they end.
 */
class Tracer: public PhasedStartup {
public:
    Tracer(std::shared_ptr<SpanStackingHandler> spanContextStack,
           std::shared_ptr<Sampler> sampler,
           std::shared_ptr<Batch> batch,
           void (^onSpanStarted)()) noexcept;
    ~Tracer() {};

    void earlyConfigure(BSGEarlyConfiguration *) noexcept;
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *config) noexcept {
        onSpanEndCallbacks_ = config.onSpanEndCallbacks;
        attributeCountLimit_ = config.attributeCountLimit;
    };
    void preStartSetup() noexcept;
    void start() noexcept {}

    void setOnViewLoadSpanStarted(std::function<void(NSString *)> onViewLoadSpanStarted) noexcept {
        onViewLoadSpanStarted_ = onViewLoadSpanStarted;
    }

    BugsnagPerformanceSpan *startAppStartSpan(NSString *name, SpanOptions options) noexcept;

    BugsnagPerformanceSpan *startCustomSpan(NSString *name, SpanOptions options) noexcept;

    BugsnagPerformanceSpan *startViewLoadSpan(BugsnagPerformanceViewType viewType,
                                              NSString *className,
                                              SpanOptions options) noexcept;

    BugsnagPerformanceSpan *startNetworkSpan(NSString *httpMethod, SpanOptions options) noexcept;

    BugsnagPerformanceSpan *startViewLoadPhaseSpan(NSString *className,
                                                   NSString *phase,
                                                   BugsnagPerformanceSpanContext *parentContext) noexcept;

    void cancelQueuedSpan(BugsnagPerformanceSpan *span) noexcept;

    void onPrewarmPhaseEnded(void) noexcept;
    
    void abortAllOpenSpans() noexcept;

    // Sweep must be called periodically to avoid a buildup of dead pointers.
    void sweep() noexcept;

    void callOnSpanEndCallbacks(BugsnagPerformanceSpan *span);

private:
    Tracer() = delete;
    std::shared_ptr<Sampler> sampler_;
    std::shared_ptr<SpanStackingHandler> spanStackingHandler_;

    std::atomic<bool> willDiscardPrewarmSpans_{false};
    std::mutex prewarmSpansMutex_;
    NSMutableArray<BugsnagPerformanceSpan *> *prewarmSpans_;
    NSArray<BugsnagPerformanceSpanEndCallback> *onSpanEndCallbacks_;
    NSUInteger attributeCountLimit_{128};

    // Sloppy list of "open" spans. Some spans may have already been closed,
    // but span abort/end are idempotent so it doesn't matter.
    std::shared_ptr<WeakSpansList> potentiallyOpenSpans_;

    std::shared_ptr<Batch> batch_;
    void (^onSpanStarted_)(){ ^(){} };
    std::function<void(NSString *)> onViewLoadSpanStarted_{ [](NSString *){} };

    BugsnagPerformanceSpan *startSpan(NSString *name, SpanOptions options, BSGFirstClass defaultFirstClass) noexcept;
    void markPrewarmSpan(BugsnagPerformanceSpan *span) noexcept;
    void onSpanClosed(BugsnagPerformanceSpan *span);
    void reprocessEarlySpans(void);
};
}
