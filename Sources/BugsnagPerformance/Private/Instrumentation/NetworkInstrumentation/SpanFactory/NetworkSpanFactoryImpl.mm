//
//  NetworkSpanFactoryImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NetworkSpanFactoryImpl.h"

BugsnagPerformanceSpan *
NetworkSpanFactoryImpl::startOverallNetworkSpan(NSString *httpMethod,
                                                NSURL * _Nullable url,
                                                NSError * _Nullable error) noexcept {
    SpanOptions options;
    options.makeCurrentContext = false;
    auto span = tracer_->startNetworkSpan(httpMethod, options);
    if (url != nil) {
        [span internalSetMultipleAttributes:spanAttributesProvider_->networkSpanUrlAttributes(url, error)];
    }
    return span;
}
