//
//  NetworkSpanReporterImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 22/10/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "../Span/BugsnagPerformanceSpan+Private.h"
#import "NetworkSpanReporterImpl.h"

using namespace bugsnag;

void
NetworkSpanReporterImpl::reportNetworkSpan(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept {
    BugsnagPerformanceSpan *span = nil;

    NSError *errorFromGetRequest = nil;
    NSURLRequest *req = getTaskRequest(task, &errorFromGetRequest);

    auto info = [BugsnagPerformanceNetworkRequestInfo new];
    info.url = req.URL;
    bool userVetoedTracing = false;
    if (info.url != nil && networkRequestCallback_ != nullptr) {
        info = networkRequestCallback_(info);
        userVetoedTracing = info.url == nil;
    }
    if (!userVetoedTracing) {
        auto interval = metrics.taskInterval;
        auto name = req.HTTPMethod;
        SpanOptions options;
        options.makeCurrentContext = false;
        options.startTime = dateToAbsoluteTime(interval.startDate);
        auto attributes = spanAttributesProvider_->networkSpanAttributes(info.url, task, metrics, errorFromGetRequest);
        span = networkSpanFactory_->startNetworkSpan(name, options, attributes);
        [span endWithEndTime:interval.endDate];
    }
}
