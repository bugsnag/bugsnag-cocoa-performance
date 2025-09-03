//
//  NetworkLifecycleHandlerImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NetworkLifecycleHandlerImpl.h"
#import "../../../BugsnagPerformanceSpan+Private.h"

using namespace bugsnag;

void
NetworkLifecycleHandlerImpl::onInstrumentationConfigured(bool isEnabled,
                                                         BugsnagPerformanceNetworkRequestCallback callback) noexcept {
    networkRequestCallback_ = callback;
    NetworkEarlyPhaseHandlerStateCallback stateCallback = ^(NetworkInstrumentationState *state) {
        updateStateInfo(state);
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
                                                   req.HTTPMethod,
                                                   req.URL,
                                                   errorFromGetRequest);
    if (state.url == nil) {
        // We couldn't get the request URL, so the metrics phase won't happen either.
        // As a fallback, make it end the span when it gets dropped and destroyed.
        [state.overallSpan endOnDestroy];
    }

    networkHeaderInjector_->injectTraceParentIfMatches(task, state.overallSpan);
}

#pragma mark Helpers

void
NetworkLifecycleHandlerImpl::updateStateInfo(NetworkInstrumentationState *state) {
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
                                                               NSString *httpMethod,
                                                               NSURL *originalUrl,
                                                               NSError *error) noexcept {
    auto state = [NetworkInstrumentationState new];
    state.url = originalUrl;
    updateStateInfo(state);
    if (!state.hasBeenVetoed) {
        state.overallSpan = spanFactory_->startOverallNetworkSpan(httpMethod, state.url, error);
        repository_->setInstrumentationState(task, state);
        earlyPhaseHandler_->onNewStateCreated(state);
        return state;
    }
    return nil;
}
