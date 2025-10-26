//
//  NetworkHeaderInjector.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 29.04.24.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import "../../../Core/PhasedStartup.h"
#import "../../../Core/Attributes/SpanAttributesProvider.h"
#import "../../../Core/SpanStack/SpanStackingHandler.h"
#import "../../../Core/Sampler/Sampler.h"

#import <memory>

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

class NetworkHeaderInjector: public PhasedStartup {
public:
    NetworkHeaderInjector(std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                          std::shared_ptr<SpanStackingHandler> spanStackingHandler,
                          std::shared_ptr<Sampler> sampler) noexcept
    : spanAttributesProvider_(spanAttributesProvider)
    , spanStackingHandler_(spanStackingHandler)
    , sampler_(sampler)
    {}
    virtual ~NetworkHeaderInjector() {}

    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept {}
    void start() noexcept {}

    void injectTraceParentIfMatches(NSURLSessionTask *task, BugsnagPerformanceSpan * _Nullable span);

private:
    BOOL shouldAddTracePropagationHeaders(NSURL *url) noexcept;
    NSString *generateTraceParent(BugsnagPerformanceSpan * _Nullable span) noexcept;
    void injectHeaders(NSURLSessionTask *task, BugsnagPerformanceSpan * _Nullable span);

    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    NSSet<NSRegularExpression *> * _Nullable propagateTraceParentToUrlsMatching_;
    std::shared_ptr<Sampler> sampler_;
    std::shared_ptr<SpanStackingHandler> spanStackingHandler_;
};
}

NS_ASSUME_NONNULL_END
