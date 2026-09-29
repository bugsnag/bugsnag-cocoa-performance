//
//  NetworkSpanFactoryImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NetworkSpanFactoryImpl.h"

using namespace bugsnag;

BugsnagPerformanceSpan *
NetworkSpanFactoryImpl::startOverallNetworkSpan(NSString *httpMethod,
                                                NSURL * _Nullable url,
                                                NSError * _Nullable error) noexcept {
    SpanOptions options;
    options.makeCurrentContext = false;
    auto attributes = spanAttributesProvider_->networkSpanUrlAttributes(url, error);
    return startNetworkSpan(httpMethod, options, attributes);
}

BugsnagPerformanceSpan *
NetworkSpanFactoryImpl::startInternalErrorSpan(NSString *httpMethod,
                                               NSError *error) noexcept {
    SpanOptions options;
    options.makeCurrentContext = false;
    auto attributes = spanAttributesProvider_->internalErrorAttributes(error);
    return startNetworkSpan(httpMethod, options, attributes);
}

BugsnagPerformanceSpan *
NetworkSpanFactoryImpl::startNetworkSpan(NSString *httpMethod,
                                         const SpanOptions &options,
                                         NSDictionary *attributes) noexcept {
    auto name = [NSString stringWithFormat:@"[HTTP/%@]", httpMethod ?: @"unknown"];
    return startNetworkSpan(name, options, BSGTriStateUnset, attributes);
}

BugsnagPerformanceSpan *
NetworkSpanFactoryImpl::startNetworkSpan(NSString *spanName,
                                         const SpanOptions &options,
                                         BSGTriState firstClass,
                                         NSDictionary *attributes) noexcept {
    NSMutableDictionary *spanAttributes = spanAttributesProvider_->initialNetworkSpanAttributes();
    [spanAttributes addEntriesFromDictionary:attributes];
    return plainSpanFactory_->startSpan(spanName, options, firstClass, SPAN_KIND_CLIENT, spanAttributes, @[]);
}
