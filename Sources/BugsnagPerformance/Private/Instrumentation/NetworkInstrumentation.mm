//
//  NetworkInstrumentation.m
//  
//
//  Created by Karl Stenerud on 14.10.22.
//

#import "NetworkInstrumentation.h"
#import "NetworkInstrumentation/NSURLSession+Instrumentation.h"
#import "NetworkInstrumentation/NSURLSessionTask+Instrumentation.h"

#import "../BugsnagPerformanceSpan+Private.h"
#import "../Span.h"
#import "../SpanAttributesProvider.h"

#import <objc/runtime.h>

#if 0
#define Trace NSLog
#else
#define Trace(...)
#endif

using namespace bugsnag;

static const int associatedSpan = 0;
static const void *associatedNetworkSpanKey = &associatedSpan;

@interface BSGURLSessionPerformanceDelegate () <NSURLSessionTaskDelegate, BSGPhasedStartup>

@property(readwrite,nonatomic) BOOL isEnabled;
@property(readonly,nonatomic) std::shared_ptr<Tracer> tracer;
@property(readonly,nonatomic) std::shared_ptr<SpanAttributesProvider> spanAttributesProvider;
@property(readwrite,strong,nonatomic) NSString *baseEndpointStr;

- (instancetype) initWithTracer:(std::shared_ptr<Tracer>)tracer
         spanAttributesProvider:(std::shared_ptr<SpanAttributesProvider>)spanAttributesProvider;

@end

@implementation BSGURLSessionPerformanceDelegate

- (instancetype) initWithTracer:(std::shared_ptr<Tracer>)tracer
         spanAttributesProvider:(std::shared_ptr<SpanAttributesProvider>)spanAttributesProvider {
    if ((self = [super init]) != nil) {
        _tracer = tracer;
        _spanAttributesProvider = spanAttributesProvider;
    }
    return self;
}

- (void)earlyConfigure:(BSGEarlyConfiguration *)config {
    self.isEnabled = config.enableSwizzling;
}

- (void)earlySetup {

}

- (void)configure:(BugsnagPerformanceConfiguration *)config {
    self.isEnabled &= config.autoInstrumentNetworkRequests;
    self.baseEndpointStr = config.endpoint.absoluteString;
}

- (void)start {

}

- (void)URLSession:(__unused NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics
API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {
    if (!self.isEnabled) {
        return;
    }

    NSError *errorFromGetRequest = nil;
    auto request = getTaskRequest(task, &errorFromGetRequest);
    auto httpResponse = BSGDynamicCast<NSHTTPURLResponse>(task.response);

    if (task.error != nil || task.response == nil || httpResponse.statusCode == 0) {
        return;
    }

    if (self.baseEndpointStr.length > 0 && [request.URL.absoluteString hasPrefix:self.baseEndpointStr]) {
        return;
    }

    auto span = (BugsnagPerformanceSpan *)objc_getAssociatedObject(task, associatedNetworkSpanKey);
    if (!span) {
        return;
    }

    objc_setAssociatedObject(self, associatedNetworkSpanKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [span addAttributes:self.spanAttributesProvider->networkSpanAttributes(nil, task, metrics, errorFromGetRequest)];
    [span endWithEndTime:metrics.taskInterval.endDate];
}

@end

NetworkInstrumentation::NetworkInstrumentation(std::shared_ptr<Tracer> tracer,
                                               std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                                               std::shared_ptr<NetworkHeaderInjector> networkHeaderInjector) noexcept
: isEnabled_(true)
, isEarlySpansPhase_(true)
, tracer_(tracer)
, spanAttributesProvider_(spanAttributesProvider)
, networkHeaderInjector_(networkHeaderInjector)
, earlySpans_([NSMutableArray new])
, delegate_([[BSGURLSessionPerformanceDelegate alloc] initWithTracer:tracer_
                                              spanAttributesProvider:spanAttributesProvider_])
, checkIsEnabled_(^() { return isEnabled_; })
, onSessionTaskResume_(^(NSURLSessionTask *task) { NSURLSessionTask_resume(task); })
{}

void NetworkInstrumentation::earlyConfigure(BSGEarlyConfiguration *config) noexcept {
    [delegate_ earlyConfigure:config];

    isEnabled_ = config.enableSwizzling;
}

void NetworkInstrumentation::earlySetup() noexcept {
    [delegate_ earlySetup];

    if (!isEnabled_) {
        return;
    }

    bsg_installNSURLSessionPerformance(delegate_, checkIsEnabled_);
    bsg_installNSURLSessionTaskPerformance(onSessionTaskResume_);
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
    propagateTraceParentToUrlsMatching_ = config.propagateTraceParentToUrlsMatching;
    endEarlySpansPhase();
}

void NetworkInstrumentation::start() noexcept {
    Trace(@"NetworkInstrumentation::start()");
    [delegate_ start];
}

void NetworkInstrumentation::markEarlySpan(BugsnagPerformanceSpan *span) noexcept {
    std::lock_guard<std::mutex> guard(earlySpansMutex_);
    [earlySpans_ addObject:span];
}

static bool didVetoTracing(NSURL * _Nullable originalUrl,
                           BugsnagPerformanceNetworkRequestInfo * _Nullable info) noexcept {
    // A user changing the request URL to nil signals a veto
    return originalUrl != nil && info.url == nil;
}

void NetworkInstrumentation::endEarlySpansPhase() noexcept {
    std::lock_guard<std::mutex> guard(earlySpansMutex_);
    isEarlySpansPhase_ = false;
    auto spans = earlySpans_;
    earlySpans_ = nil;
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
            [span endOnDestroy];
        } else {
            [span addAttributes:spanAttributesProvider_->networkSpanUrlAttributes(info.url, nil)];
        }
    }
}

bool NetworkInstrumentation::canTraceTask(NSURLSessionTask *task) noexcept {
    NSURLRequest *req = getTaskCurrentRequest(task, nil);
    if (req == nil) {
        // We still want to trace the task and report an error.
        return true;
    }

    NSURL *url = req.URL;
    if (url == nil) {
        // We still want to trace the task and report an error.
        return true;
    }

    if ([url.scheme isEqualToString:@"file"]) {
        BSGLogTrace(@"Task %@ has forbidden file scheme in URL %@", task.class, url);
        // Don't track local activity.
        return false;
    }

    return true;
}

void NetworkInstrumentation::NSURLSessionTask_resume(NSURLSessionTask *task) noexcept {
    if (!isEnabled_) {
        return;
    }

    if (!canTraceTask(task)) {
        BSGLogDebug(@"We cannot trace task %@", task.class);
        return;
    }

    NSError *errorFromGetRequest = nil;
    auto req = getTaskRequest(task, &errorFromGetRequest);
    auto info = [BugsnagPerformanceNetworkRequestInfo new];
    info.url = req.URL;
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
            [span endOnDestroy];
        } else {
            [span addAttributes:spanAttributesProvider_->networkSpanUrlAttributes(info.url, errorFromGetRequest)];
        }
        if (span != nil) {
            objc_setAssociatedObject(task, associatedNetworkSpanKey, span,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            if (isEarlySpansPhase_) {
                markEarlySpan(span);
            }
        }
    }

    networkHeaderInjector_->injectTraceParentIfMatches(task, span);
}
