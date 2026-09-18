//
//  NetworkLifecycleHandlerImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NetworkLifecycleHandlerImpl.h"
#import "../../../BugsnagPerformanceSpan+Private.h"
#import "../../../Utils.h"
#import "../../../SpanAttributesProvider.h"

using namespace bugsnag;

static NSString * const BSGGraphQLResponseHasErrorsAttribute = @"bugsnag.internal.graphql.response_has_errors";
static const NSUInteger BSGMaxGraphQLResponseBodyInspectionBytes = 64 * 1024;

extern "C" NSData *BSGCapturedGraphQLResponseBodyForTask(NSURLSessionTask *task);
extern "C" void BSGClearCapturedGraphQLResponseBodyForTask(NSURLSessionTask *task);

static BOOL BSGGraphQLResponseBodyHasErrors(NSData *body) {
    if (body.length == 0 || body.length > BSGMaxGraphQLResponseBodyInspectionBytes) {
        return NO;
    }
    
    NSError *error = nil;
    id json = [NSJSONSerialization JSONObjectWithData:body options:0 error:&error];
    NSDictionary *dictionary = BSGDynamicCast<NSDictionary>(json);
    NSArray *errors = BSGDynamicCast<NSArray>(dictionary[@"errors"]);
    if (errors.count > 0) {
        return YES;
    }
    if (errors != nil) {
        return NO;
    }
    
    // Some servers may return a JSON string containing encoded JSON. Parse that once more.
    NSString *jsonString = BSGDynamicCast<NSString>(json);
    if (dictionary == nil && jsonString.length > 0) {
        NSData *nestedData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        if (nestedData.length > 0) {
            id nestedJson = [NSJSONSerialization JSONObjectWithData:nestedData options:0 error:nil];
            NSDictionary *nestedDictionary = BSGDynamicCast<NSDictionary>(nestedJson);
            NSArray *nestedErrors = BSGDynamicCast<NSArray>(nestedDictionary[@"errors"]);
            if (nestedErrors.count > 0) {
                return YES;
            }
            if (nestedErrors != nil) {
                return NO;
            }
        }
    }
    
    NSString *stringBody = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
    if (stringBody.length == 0) {
        return NO;
    }
    
    NSString *normalizedBody = [[stringBody stringByReplacingOccurrencesOfString:@"\n" withString:@""]
                                stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *looselyUnescapedBody = [normalizedBody stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    
    BOOL hasExplicitEmptyErrorsArray = [normalizedBody containsString:@"\"errors\":[]"] ||
    [normalizedBody containsString:@"\\\"errors\\\":[]"] ||
    [looselyUnescapedBody containsString:@"\"errors\":[]"];
    if (hasExplicitEmptyErrorsArray) {
        return NO;
    }
    
    BOOL hasErrorsArray = [normalizedBody containsString:@"\"errors\":["] ||
    [normalizedBody containsString:@"\\\"errors\\\":["] ||
    [looselyUnescapedBody containsString:@"\"errors\":["];
    return hasErrorsArray;
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
    if (req == nil || req.URL == nil) {
        reportInternalErrorSpan(req.HTTPMethod, errorFromGetRequest);
        return;
    }
    auto state = initializeStateAndSaveIfNotVetoed(task,
                                                   req,
                                                   errorFromGetRequest);
    if (state == nil) {
        return;
    }
    networkHeaderInjector_->injectTraceParentIfMatches(task, state.overallSpan);
}

void
NetworkLifecycleHandlerImpl::onTaskDidFinishCollectingMetrics(
                                                              NSURLSessionTask *task,
                                                              NSURLSessionTaskMetrics *metrics,
                                                              NSString *ignoreBaseEndpoint) noexcept
{
    
    auto state = repository_->getInstrumentationState(task);
    if (state.overallSpan == nil) {
        return;
    }
    
    NSError *error = nil;
    
    if (!shouldRecordFinishedTask(task, ignoreBaseEndpoint, &error)) {
        BSGClearCapturedGraphQLResponseBodyForTask(task);
        [state.overallSpan cancel];
        repository_->setInstrumentationState(task, nil);
        return;
    }
    
    auto networkAttributes = spanAttributesProvider_->networkSpanAttributes(nil, task, metrics, error);
    if (networkAttributes != nil) {
        [state.overallSpan internalSetMultipleAttributes:networkAttributes];
    }
    
    // Reapply GraphQL attributes (networkSpanAttributes overwrites category).
    NSDictionary *graphQLAttributes = state.graphQLAttributes;
    
    if (graphQLAttributes != nil) {
        [state.overallSpan internalSetMultipleAttributes:graphQLAttributes];
        
        NSData *responseBody = BSGCapturedGraphQLResponseBodyForTask(task);
        
        NSHTTPURLResponse *httpResponse =
        BSGDynamicCast<NSHTTPURLResponse>(task.response);
        NSInteger statusCode = httpResponse ? httpResponse.statusCode : 0;
        
        if (responseBody.length == 0 && statusCode > 0 && statusCode < 400) {
            // For completion-handler-based tasks, the response body is stored
            // by the wrapped completion handler, which fires AFTER this callback.
            // Defer span finalization to allow body capture to complete.
            NSDate *endTime = metrics.taskInterval.endDate;
            auto repo = repository_;
            
            dispatch_after(
                           dispatch_time(DISPATCH_TIME_NOW, (int64_t)(100 * NSEC_PER_MSEC)),
                           dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
                               
                               NSData *deferredBody = BSGCapturedGraphQLResponseBodyForTask(task);
                               
                               if (BSGGraphQLResponseBodyHasErrors(deferredBody)) {
                                   [state.overallSpan internalSetAttribute:
                                    BSGGraphQLResponseHasErrorsAttribute
                                                                 withValue:@YES];
                               }
                               
                               BSGClearCapturedGraphQLResponseBodyForTask(task);
                               [state.overallSpan endWithEndTime:endTime];
                               repo->setInstrumentationState(task, nil);
                           });
            return; // Don't end span here — deferred block will do it
        }
        
        // Body available immediately (delegate-based task) or HTTP error status
        BOOL graphQLResponseHasErrors = BSGGraphQLResponseBodyHasErrors(responseBody);
        
        if (graphQLResponseHasErrors) {
            [state.overallSpan internalSetAttribute:
             BSGGraphQLResponseHasErrorsAttribute
                                          withValue:@YES];
        }
    }
    
    BSGClearCapturedGraphQLResponseBodyForTask(task);
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
    if (request == nil) {
        return nil;
    }
    auto state = [NetworkInstrumentationState new];
    state.url = request.URL;
    updateState(state);
    if (!state.hasBeenVetoed) {
        auto graphQLAttributes = spanAttributesProvider_->graphQLAttributes(request, state.url);
        NSString *graphQLSpanName = graphQLAttributes != nil
            ? spanAttributesProvider_->graphQLSpanName(state.url, graphQLAttributes)
            : nil;
        if (graphQLSpanName != nil && graphQLAttributes != nil) {
            [graphQLAttributes removeObjectsForKeys:@[BSGGraphQLOperationTypeAttributeKey,
                                                      BSGGraphQLOperationNameAttributeKey]];
            state.graphQLAttributes = graphQLAttributes;
            SpanOptions options;
            options.makeCurrentContext = false;
            auto initialAttributes = spanAttributesProvider_->networkSpanUrlAttributes(state.url, error);
            if (initialAttributes != nil) {
                [initialAttributes addEntriesFromDictionary:graphQLAttributes];
            } else {
                initialAttributes = graphQLAttributes.mutableCopy;
            }
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
