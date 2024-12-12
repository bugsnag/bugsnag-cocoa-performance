//
//  NetworkHeaderInjector.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 29.04.24.
//  Copyright © 2024 Bugsnag. All rights reserved.
//

#import "NetworkHeaderInjector.h"
#import "Utils.h"

void NetworkHeaderInjector::configure(BugsnagPerformanceConfiguration *config) noexcept {
    propagateTraceParentToUrlsMatching_ = config.tracePropagationUrls;
}

NSString *NetworkHeaderInjector::generateTraceParent(BugsnagPerformanceSpan *span) noexcept {
    if (span == nil) {
        span = spanStackingHandler_->currentSpan();
    }
    if (span == nil) {
        return nil;
    }
    // Sampled status assumes that the current P value won't change soon.
    return [NSString stringWithFormat:@"00-%016llx%016llx-%016llx-0%d",
            span.traceIdHi, span.traceIdLo,
            span.spanId, sampler_->sampled(span)];
}

@protocol RequestSetter <NSObject>
- (void) setCurrentRequest:(NSURLRequest *)request;
@end

void NetworkHeaderInjector::injectHeaders(NSURLSessionTask *task, BugsnagPerformanceSpan *span) {
    NSString *headerName = @"traceparent";
    NSString *headerValue = generateTraceParent(span);
    
    if (headerValue == nil) {
        return;
    }

    NSURLRequest *request = getTaskCurrentRequest(task, nil);
    if (request == nil) {
        return;
    }

    if ([request isKindOfClass:NSMutableURLRequest.class]) {
        NSMutableURLRequest *mutableRequest = (NSMutableURLRequest *)request;
        [mutableRequest setValue:headerValue forHTTPHeaderField:headerName];
        return;
    }

    // All subclasses have this method, but check to be safe...
    if ([request respondsToSelector:@selector(setCurrentRequest:)]) {
        NSMutableURLRequest *mutableRequest = [request mutableCopy];
        [mutableRequest setValue:headerValue forHTTPHeaderField:headerName];
        [((id<RequestSetter>)task) setCurrentRequest:mutableRequest];
    }
}

BOOL NetworkHeaderInjector::shouldAddTracePropagationHeaders(NSURL *url) noexcept {
    NSString *urlStr = url.absoluteString;
    NSRange range = NSMakeRange(0, [urlStr length]);
    for (NSRegularExpression *regex in propagateTraceParentToUrlsMatching_) {
        if ([regex firstMatchInString:urlStr options:0 range:range]) {
            return YES;
        }
    }
    return NO;
}

void NetworkHeaderInjector::injectTraceParentIfMatches(NSURLSessionTask *task, BugsnagPerformanceSpan * _Nullable span) {
    if (shouldAddTracePropagationHeaders(getTaskRequest(task, nil).URL)) {
        injectHeaders(task, span);
    }
}
