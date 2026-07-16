//
//  NetworkLifecycleHandlerImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NetworkLifecycleHandlerImpl.h"
#import "../../../BugsnagPerformanceSpan+Private.h"
#import "../../../OtlpTraceEncoding.h"

using namespace bugsnag;

static NSString *BSGPrettyJSONString(id object) __attribute__((unused));
static NSString *BSGPrettyJSONString(id object) {
    if (object == nil || ![NSJSONSerialization isValidJSONObject:object]) {
        return [object description];
    }
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:&error];
    if (data == nil) {
        return [NSString stringWithFormat:@"<unable to encode JSON preview: %@>", error];
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

static NSDictionary *BSGEncodedPayloadPreview(std::shared_ptr<ResourceAttributes> resourceAttributes,
                                              BugsnagPerformanceSpan *span) __attribute__((unused));
static NSDictionary *BSGEncodedPayloadPreview(std::shared_ptr<ResourceAttributes> resourceAttributes,
                                              BugsnagPerformanceSpan *span) {
    OtlpTraceEncoding encoder;
    NSDictionary *encodeResourceAttributes = resourceAttributes != nullptr ? resourceAttributes->get() : @{};
    return @{
        @"resourceSpans": @[@{
            @"resource": @{
                @"attributes": encoder.encode(encodeResourceAttributes ?: @{}),
            },
            @"scopeSpans": @[@{
                @"scope": @{
                    @"name": @"bugsnag.performance",
                },
                @"spans": @[encoder.encode(span)],
            }],
        }]
    };
}

void
NetworkLifecycleHandlerImpl::onInstrumentationConfigured(bool isEnabled,
                                                         BugsnagPerformanceNetworkRequestCallback callback) noexcept {
    networkRequestCallback_ = callback;
    NetworkEarlyPhaseHandlerStateCallback stateCallback = ^(NetworkInstrumentationState *state) {
        updateState(state);
    };
    earlyPhaseHandler_->onEarlyPhaseEnded(isEnabled, stateCallback);
}

void
NetworkLifecycleHandlerImpl::onTaskResume(NSURLSessionTask *task) noexcept {
    if (!canTraceTask(task)) {
        return;
    }

    NSError *errorFromGetRequest = nil;
    auto req = systemUtils_->taskRequest(task, &errorFromGetRequest);
    if (req.URL == nil) {
        reportInternalErrorSpan(req.HTTPMethod, errorFromGetRequest);
        return;
    }
    auto state = initializeStateAndSaveIfNotVetoed(task,
                                                   req,
                                                   errorFromGetRequest);
    if (state.graphQLAttributes != nil) {
        BSGLogDebug(@"GraphQL span started: method=%@ endpoint=%@ name=%@ category=%@ display_name=%@ finalPayloadLog=\"GraphQL upload payload preview\"",
                    req.HTTPMethod,
                    state.url.path.length > 0 ? state.url.path : @"/",
                    state.overallSpan.name,
                    state.graphQLAttributes[@"bugsnag.span.category"],
                    state.graphQLAttributes[@"display_name"]);
    } else {
        BSGLogDebug(@"Network span started: method=%@ endpoint=%@ category=network graphQLDetected=NO spanName=%@",
                    req.HTTPMethod,
                    state.url.path.length > 0 ? state.url.path : @"/",
                    state.overallSpan.name);
    }
    networkHeaderInjector_->injectTraceParentIfMatches(task, state.overallSpan);
}

void
NetworkLifecycleHandlerImpl::onTaskDidFinishCollectingMetrics(NSURLSessionTask *task,
                                                              NSURLSessionTaskMetrics *metrics,
                                                              NSString *ignoreBaseEndpoint) noexcept {
    auto state = repository_->getInstrumentationState(task);
    if (state.overallSpan == nil) {
        return;
    }
    NSError *error = nil;
    if (!shouldRecordFinishedTask(task, ignoreBaseEndpoint, &error)) {
        [state.overallSpan cancel];
        repository_->setInstrumentationState(task, nil);
        return;
    }
    
    [state.overallSpan internalSetMultipleAttributes:spanAttributesProvider_->networkSpanAttributes(nil, task, metrics, error)];
    // Network completion attributes contain the default network category. Reapply the
    // GraphQL classification after them without reparsing the request body.
    NSDictionary *graphQLAttributes = state.graphQLAttributes;
    if (graphQLAttributes != nil) {
        [state.overallSpan internalSetMultipleAttributes:graphQLAttributes];
    } else {
        auto httpResponse = BSGDynamicCast<NSHTTPURLResponse>(task.response);
        auto request = systemUtils_->taskRequest(task, nil);
    }
    [state.overallSpan endWithEndTime:metrics.taskInterval.endDate];
    repository_->setInstrumentationState(task, nil);
}


#pragma mark Helpers

void
NetworkLifecycleHandlerImpl::updateState(NetworkInstrumentationState *state) {
    NSURL *originalUrl = state.url;
    auto info = [BugsnagPerformanceNetworkRequestInfo new];
    info.url = state.url;
    bool hasBeenVetoed = false;
    if (networkRequestCallback_) {
        info = networkRequestCallback_(info);
        hasBeenVetoed = didVetoTracing(originalUrl, info);
    }
    state.url = info.url;
    state.hasBeenVetoed = hasBeenVetoed;
    endSpanOnDestroyIfNeeded(state);
}

bool
NetworkLifecycleHandlerImpl::didVetoTracing(NSURL *originalUrl,
                                            BugsnagPerformanceNetworkRequestInfo *info) noexcept {
    // A user changing the request URL to nil signals a veto
    bool userVetoedTracing = originalUrl != nil && info.url == nil;
    if (userVetoedTracing) {
        BSGLogDebug(@"User vetoed tracing on %@", originalUrl);
        return true;
    }
    BSGLogTrace(@"User did not veto tracing on %@", originalUrl);
    return false;
}

bool
NetworkLifecycleHandlerImpl::canTraceTask(NSURLSessionTask *task) noexcept {
    NSURLRequest *req = systemUtils_->taskCurrentRequest(task, nil);
    if (req == nil) {
        BSGLogTrace(@"Task %@ has nil request but we still want to trace it and report an error", task.class);
        return true;
    }

    NSURL *url = req.URL;
    if (url == nil) {
        BSGLogTrace(@"Task %@ request has nil URL but we still want to trace it and report an error", task.class);
        return true;
    }

    if ([url.scheme isEqualToString:@"file"]) {
        BSGLogTrace(@"Task %@ has forbidden file scheme in URL %@, so we won't trace it", task.class, url);
        // Don't track local activity.
        return false;
    }

    return true;
}

void
NetworkLifecycleHandlerImpl::reportInternalErrorSpan(NSString *httpMethod,
                                                     NSError *error) noexcept {
    auto span = spanFactory_->startInternalErrorSpan(httpMethod, error);
    [span end];
}

NetworkInstrumentationState *
NetworkLifecycleHandlerImpl::initializeStateAndSaveIfNotVetoed(NSURLSessionTask *task,
                                                               NSURLRequest *request,
                                                               NSError *error) noexcept {
    auto state = [NetworkInstrumentationState new];
    state.url = request.URL;
    updateState(state);
    if (!state.hasBeenVetoed) {
        auto graphQLAttributes = spanAttributesProvider_->graphQLAttributes(request, state.url);
        NSString *graphQLSpanName = spanAttributesProvider_->graphQLSpanName(state.url, graphQLAttributes);
        if (graphQLSpanName != nil) {
            [graphQLAttributes removeObjectsForKeys:@[@"graphql.operation.type", @"graphql.operation.name"]];
            state.graphQLAttributes = graphQLAttributes;
            SpanOptions options;
            options.makeCurrentContext = false;
            auto initialAttributes = spanAttributesProvider_->networkSpanUrlAttributes(state.url, error);
            [initialAttributes addEntriesFromDictionary:graphQLAttributes];
            state.overallSpan = spanFactory_->startNetworkSpan(graphQLSpanName,
                                                               options,
                                                               BSGTriStateYes,
                                                               initialAttributes);
        } else {
            state.overallSpan = spanFactory_->startOverallNetworkSpan(request.HTTPMethod, state.url, error);
        }
        repository_->setInstrumentationState(task, state);
        earlyPhaseHandler_->onNewStateCreated(state);
        return state;
    }
    return nil;
}

void
NetworkLifecycleHandlerImpl::endSpanOnDestroyIfNeeded(NetworkInstrumentationState *state) noexcept {
    if (state.overallSpan == nil) {
        return;
    }
    if (state.url == nil) {
        // We couldn't get the request URL, so the metrics phase won't happen either.
        // As a fallback, make it end the span when it gets dropped and destroyed.
        [state.overallSpan endOnDestroy];
    }
}

bool
NetworkLifecycleHandlerImpl::shouldRecordFinishedTask(NSURLSessionTask *task,
                                                      NSString *ignoreBaseEndpoint,
                                                      NSError **error) noexcept {
    if (task.error != nil) {
        return false;
    }
    if (task.response == nil) {
        return false;
    }
    auto request = systemUtils_->taskRequest(task, error);
    auto httpResponse = BSGDynamicCast<NSHTTPURLResponse>(task.response);

    if (httpResponse.statusCode == 0) {
        return false;
    }

    if (ignoreBaseEndpoint.length > 0 && [request.URL.absoluteString hasPrefix:ignoreBaseEndpoint]) {
        return false;
    }
    return true;
}
