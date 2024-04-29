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

    auto httpResponse = BSGDynamicCast<NSHTTPURLResponse>(task.response);

    if (task.error != nil || task.response == nil || httpResponse.statusCode == 0) {
        return;
    }

    if (self.baseEndpointStr.length > 0 && [task.originalRequest.URL.absoluteString hasPrefix:self.baseEndpointStr]) {
        return;
    }

    auto span = (BugsnagPerformanceSpan *)objc_getAssociatedObject(task, associatedNetworkSpanKey);
    if (!span) {
        return;
    }

    objc_setAssociatedObject(self, associatedNetworkSpanKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [span addAttributes:self.spanAttributesProvider->networkSpanAttributes(nil, task, metrics)];
    [span endWithEndTime:metrics.taskInterval.endDate];
}

@end

NetworkInstrumentation::NetworkInstrumentation(std::shared_ptr<Tracer> tracer,
                                               std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                                               std::shared_ptr<SpanStackingHandler> spanStackingHandler,
                                               std::shared_ptr<Sampler> sampler) noexcept
: isEnabled_(true)
, isEarlySpansPhase_(true)
, tracer_(tracer)
, spanAttributesProvider_(spanAttributesProvider)
, spanStackingHandler_(spanStackingHandler)
, sampler_(sampler)
, earlySpans_([NSMutableArray new])
, delegate_([[BSGURLSessionPerformanceDelegate alloc] initWithTracer:tracer_
                                              spanAttributesProvider:spanAttributesProvider_])
, checkIsEnabled_(^() { return isEnabled_; })
, onSessionTaskResume_(^(NSURLSessionTask *task) { NSURLSessionTask_resume(task); })
, networkRequestCallback_(
    ^BugsnagPerformanceNetworkRequestInfo * _Nonnull(BugsnagPerformanceNetworkRequestInfo * _Nonnull info) {
        return info;
    }
)
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

void NetworkInstrumentation::endEarlySpansPhase() noexcept {
    std::lock_guard<std::mutex> guard(earlySpansMutex_);
    isEarlySpansPhase_ = false;
    auto spans = earlySpans_;
    earlySpans_ = nil;
    for (BugsnagPerformanceSpan *span: spans) {
        auto info = [BugsnagPerformanceNetworkRequestInfo new];
        NSString *urlString = [span getAttribute:spanAttributesProvider_->httpUrlAttributeKey()];
        info.url = [NSURL URLWithString:urlString];
        // We have to check again because the real callback might not have been set initially.
        info = networkRequestCallback_(info);
        if (info.url != nil) {
            [span addAttributes:spanAttributesProvider_->networkSpanUrlAttributes(info.url)];
        } else {
            tracer_->cancelQueuedSpan(span);
        }
    }
}

BOOL NetworkInstrumentation::shouldAddTracePropagationHeaders(NSURL *url) noexcept {
    NSString *urlStr = url.absoluteString;
    NSRange range = NSMakeRange(0, [urlStr length]);
    for (NSRegularExpression *regex in propagateTraceParentToUrlsMatching_) {
        if ([regex firstMatchInString:urlStr options:0 range:range]) {
            return YES;
        }
    }
    return NO;
}

NSString *NetworkInstrumentation::generateTraceParent(BugsnagPerformanceSpan *span) noexcept {
    if (span == nil) {
        span = spanStackingHandler_->currentSpan();
    }
    if (span == nil) {
        return nil;
    }
    // Sampled status assumes that the current P value won't change soon.
    return [NSString stringWithFormat:@"00-%016llx%016llx-%016llx-0%d",
            span.traceId.hi, span.traceId.lo,
            span.spanId, sampler_->sampled(span)];
}

@protocol RequestSetter <NSObject>
- (void) setCurrentRequest:(NSURLRequest *)request;
@end

void NetworkInstrumentation::injectHeaders(NSURLSessionTask *task, BugsnagPerformanceSpan *span) {
    NSString *headerName = @"traceparent";
    NSString *headerValue = generateTraceParent(span);
    
    if (headerValue == nil) {
        return;
    }

    NSURLRequest *request = task.currentRequest;
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

void NetworkInstrumentation::NSURLSessionTask_resume(NSURLSessionTask *task) noexcept {
    if (!isEnabled_) {
        return;
    }
    if ([task.currentRequest.URL.scheme isEqualToString:@"file"]) {
        return;
    }

    auto info = [BugsnagPerformanceNetworkRequestInfo new];
    info.url = task.originalRequest.URL;
    info = networkRequestCallback_(info);

    BugsnagPerformanceSpan *span = nil;

    // Nonnull url signals that we must trace this request.
    if (info.url != nil) {
        SpanOptions options;
        options.makeCurrentContext = false;
        span = tracer_->startNetworkSpan(task.originalRequest.HTTPMethod, options);
        [span addAttributes:spanAttributesProvider_->networkSpanUrlAttributes(info.url)];
        if (span != nil) {
            objc_setAssociatedObject(task, associatedNetworkSpanKey, span,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            if (isEarlySpansPhase_) {
                markEarlySpan(span);
            }
        }
    }
    
    if (shouldAddTracePropagationHeaders(task.originalRequest.URL)) {
        injectHeaders(task, span);
    }
}
