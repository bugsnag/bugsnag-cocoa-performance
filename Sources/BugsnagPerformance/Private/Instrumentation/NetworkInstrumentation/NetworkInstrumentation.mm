//
//  NetworkInstrumentation.m
//  
//
//  Created by Karl Stenerud on 14.10.22.
//

#import "NetworkInstrumentation.h"

#import "../../BugsnagPerformanceSpan+Private.h"
#import "../../SpanAttributesProvider.h"

using namespace bugsnag;

void NetworkInstrumentation::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    [delegate_ earlyConfigure:config];

    isEnabled_ = config.enableSwizzling;
}

void NetworkInstrumentation::earlySetup() noexcept {
    [delegate_ earlySetup];

    if (!isEnabled_) {
        return;
    }

    swizzlingHandler_->instrumentSession(delegate_, checkIsEnabled_);
    
    // We must do this in a separate thread to avoid a potential mutex deadlock with
    // Apple's com.apple.network.connections queue during early app startup.
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void){
        for (Class cls in systemUtils_->taskClassesToInstrument()) {
            swizzlingHandler_->instrumentTask(cls, onSessionTaskResume_);
        }
    });
}

void NetworkInstrumentation::configure(BugsnagPerformanceConfiguration *config) noexcept {
    [delegate_ configure:config];

    if (!isEnabled_ && config.autoInstrumentNetworkRequests) {
        BSGLogInfo(@"Automatic network instrumentation has been disabled because "
                   "bugsnag/performance/disableSwizzling in Info.plist is set to YES");
    }

    isEnabled_ &= config.autoInstrumentNetworkRequests;

    auto networkRequestCallback = config.networkRequestCallback;
    if (networkRequestCallback != nullptr) {
        networkRequestCallback_ = (BugsnagPerformanceNetworkRequestCallback _Nonnull)networkRequestCallback;
    }
    propagateTraceParentToUrlsMatching_ = config.tracePropagationUrls;
    endEarlySpansPhase();
}

void NetworkInstrumentation::preStartSetup() noexcept {
    [delegate_ preStartSetup];
}

void NetworkInstrumentation::start() noexcept {
    BSGLogTrace(@"NetworkInstrumentation::start()");
    [delegate_ start];
}

void NetworkInstrumentation::markEarlySpan(BugsnagPerformanceSpan *span) noexcept {
    BSGLogTrace(@"NetworkInstrumentation::markEarlySpan() for %@", span.name);
    std::lock_guard<std::mutex> guard(earlySpansMutex_);
    [earlySpans_ addObject:span];
}

static bool didVetoTracing(NSURL * _Nullable originalUrl,
                           BugsnagPerformanceNetworkRequestInfo * _Nullable info) noexcept {
    // A user changing the request URL to nil signals a veto
    bool userVetoedTracing = originalUrl != nil && info.url == nil;
    if (userVetoedTracing) {
        BSGLogDebug(@"User vetoed tracing on %@", originalUrl);
        return true;
    }
    BSGLogTrace(@"User did not veto tracing on %@", originalUrl);
    return false;
}

void NetworkInstrumentation::endEarlySpansPhase() noexcept {
    BSGLogDebug(@"NetworkInstrumentation::endEarlySpansPhase");
    std::lock_guard<std::mutex> guard(earlySpansMutex_);
    isEarlySpansPhase_ = false;
    auto spans = earlySpans_;
    earlySpans_ = nil;

    if (!isEnabled_) {
        for (BugsnagPerformanceSpan *span: spans) {
            [span abortUnconditionally];
        }
    }

    for (BugsnagPerformanceSpan *span: spans) {
        auto info = [BugsnagPerformanceNetworkRequestInfo new];
        NSString *urlString = [span getAttribute:spanAttributesProvider_->httpUrlAttributeKey()];
        NSURL *originalUrl = [NSURL URLWithString:urlString];
        info.url = originalUrl;
        bool userVetoedTracing = false;
        if (networkRequestCallback_) {
            // We have to check again because the real callback might not have been set initially.
            info = networkRequestCallback_(info);
            userVetoedTracing = didVetoTracing(originalUrl, info);
        }
        if (userVetoedTracing) {
            tracer_->cancelQueuedSpan(span);
        } else if (info.url == nil) {
            // We couldn't get the request URL, so the metrics phase won't happen either.
            // As a fallback, make it end the span when it gets dropped and destroyed.
            BSGLogTrace(@"NetworkInstrumentation::endEarlySpansPhase: info.url is nil, so we will end on destroy");
            [span endOnDestroy];
        } else {
            [span internalSetMultipleAttributes:spanAttributesProvider_->networkSpanUrlAttributes(info.url, nil)];
        }
    }
}

bool NetworkInstrumentation::canTraceTask(NSURLSessionTask *task) noexcept {
    NSURLRequest *req = getTaskCurrentRequest(task, nil);
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

void NetworkInstrumentation::NSURLSessionTask_resume(NSURLSessionTask *task) noexcept {
    if (!isEnabled_) {
        BSGLogTrace(@"NetworkInstrumentation::NSURLSessionTask_resume: Not enabled (task was %@)", task.class);
        return;
    }

    if (!canTraceTask(task)) {
        BSGLogTrace(@"NetworkInstrumentation::NSURLSessionTask_resume: Task %@ not traceable", task.class);
        return;
    }

    NSError *errorFromGetRequest = nil;
    auto req = getTaskRequest(task, &errorFromGetRequest);
    auto info = [BugsnagPerformanceNetworkRequestInfo new];
    info.url = req.URL;
    if (info.url == nil) {
        BSGLogDebug(@"NetworkInstrumentation::NSURLSessionTask_resume: Not fully tracing task with null URL");
        SpanOptions options;
        options.makeCurrentContext = false;
        auto span = tracer_->startNetworkSpan(req.HTTPMethod, options);
        if (errorFromGetRequest) {
            [span internalSetMultipleAttributes:spanAttributesProvider_->internalErrorAttributes(errorFromGetRequest)];
        }
        [span end];
        
        return;
    }
    BSGLogTrace(@"NetworkInstrumentation::NSURLSessionTask_resume: Got request from task %@ with req %@, URL %@ and error %@", task.class, req, info.url, errorFromGetRequest);
    bool userVetoedTracing = false;
    if (networkRequestCallback_) {
        info = networkRequestCallback_(info);
        BSGLogTrace(@"NetworkInstrumentation::NSURLSessionTask_resume: URL after callback is %@", info.url);
        userVetoedTracing = didVetoTracing(req.URL, info);
    }

    BugsnagPerformanceSpan *span = nil;

    if (!userVetoedTracing) {
        BSGLogDebug(@"NetworkInstrumentation::NSURLSessionTask_resume: Tracing task %@, url %@", task.class, info.url);
        SpanOptions options;
        options.makeCurrentContext = false;
        span = tracer_->startNetworkSpan(req.HTTPMethod, options);
        if (info.url == nil) {
            // We couldn't get the request URL, so the metrics phase won't happen either.
            // As a fallback, make it end the span when it gets dropped and destroyed.
            BSGLogTrace(@"NetworkInstrumentation::NSURLSessionTask_resume: info.url is nil, so we will end on destroy");
            [span endOnDestroy];
        } else {
            [span internalSetMultipleAttributes:spanAttributesProvider_->networkSpanUrlAttributes(info.url, errorFromGetRequest)];
        }
        if (span != nil) {
            auto state = [NetworkInstrumentationState new];
            state.overallSpan = span;
            repository_->setInstrumentationState(task, state);
            if (isEarlySpansPhase_) {
                markEarlySpan(span);
            }
        }
    }

    networkHeaderInjector_->injectTraceParentIfMatches(task, span);
}
