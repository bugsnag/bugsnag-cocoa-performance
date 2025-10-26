//
//  NetworkSpanReporterImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 22/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "NetworkSpanReporter.h"
#import "../Attributes/SpanAttributesProvider.h"
#import "../SpanFactory/Network/NetworkSpanFactory.h"

namespace bugsnag {

class NetworkSpanReporterImpl: public NetworkSpanReporter {
public:
    NetworkSpanReporterImpl(std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                            std::shared_ptr<NetworkSpanFactory> networkSpanFactory) noexcept
    : spanAttributesProvider_(spanAttributesProvider)
    , networkSpanFactory_(networkSpanFactory) {}
    
    void earlyConfigure(BSGEarlyConfiguration *) noexcept {}
    void earlySetup() noexcept {}
    void configure(BugsnagPerformanceConfiguration *config) noexcept {
        auto networkRequestCallback = config.networkRequestCallback;
        if (networkRequestCallback != nullptr) {
            networkRequestCallback_ = (BugsnagPerformanceNetworkRequestCallback _Nonnull)networkRequestCallback;
        }
    }
    void preStartSetup() noexcept {}
    void start() noexcept {}
    
    void reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept;
    
private:
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    std::shared_ptr<NetworkSpanFactory> networkSpanFactory_;
    
    BugsnagPerformanceNetworkRequestCallback networkRequestCallback_{nullptr};
    
    NetworkSpanReporterImpl() = delete;
};
}
