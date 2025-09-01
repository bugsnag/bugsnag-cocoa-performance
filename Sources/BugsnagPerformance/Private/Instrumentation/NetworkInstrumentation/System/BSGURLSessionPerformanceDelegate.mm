//
//  BSGURLSessionPerformanceDelegate.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 01/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "BSGURLSessionPerformanceDelegate.h"

@interface BSGURLSessionPerformanceDelegate ()

@property(readwrite,nonatomic) BOOL isEnabled;
@property(readonly,nonatomic) std::shared_ptr<Tracer> tracer;
@property(readonly,nonatomic) std::shared_ptr<SpanAttributesProvider> spanAttributesProvider;
@property(readonly,nonatomic) std::shared_ptr<NetworkInstrumentationStateRepository> repository;
@property(readwrite,strong,nonatomic) NSString *baseEndpointStr;

@end

@implementation BSGURLSessionPerformanceDelegate

- (instancetype) initWithTracer:(std::shared_ptr<Tracer>)tracer
         spanAttributesProvider:(std::shared_ptr<SpanAttributesProvider>)spanAttributesProvider
                     repository:(std::shared_ptr<NetworkInstrumentationStateRepository>)repository {
    if ((self = [super init]) != nil) {
        _tracer = tracer;
        _spanAttributesProvider = spanAttributesProvider;
        _repository = repository;
    }
    return self;
}

#pragma mark BSGPhasedStartup

- (void)earlyConfigure:(BSGEarlyConfiguration *)config {
    self.isEnabled = config.enableSwizzling;
}

- (void)earlySetup {

}

- (void)configure:(BugsnagPerformanceConfiguration *)config {
    self.isEnabled &= config.autoInstrumentNetworkRequests;
    self.baseEndpointStr = config.endpoint.absoluteString;
}

- (void)preStartSetup {

}

- (void)start {

}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(__unused NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics
API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {
    if (!self.isEnabled) {
        return;
    }

    NSError *errorFromGetRequest = nil;
    auto request = getTaskRequest(task, &errorFromGetRequest);
    auto httpResponse = BSGDynamicCast<NSHTTPURLResponse>(task.response);

    if (task.error != nil) {
        BSGLogTrace(@"NetworkInstrumentation.URLSession:%@ task:%@ didFinishCollectingMetrics for url [%@]: Task error [%@] so not recording span", session.class, task.class, request.URL, task.error);
        return;
    }
    if (task.response == nil) {
        BSGLogTrace(@"NetworkInstrumentation.URLSession:%@ task:%@ didFinishCollectingMetrics for url [%@]: Task response is nil so not recording span", session.class, task.class, request.URL);
        return;
    }
    if (httpResponse.statusCode == 0) {
        BSGLogTrace(@"NetworkInstrumentation.URLSession:%@ task:%@ didFinishCollectingMetrics for url [%@]: Task response status code is 0 so not recording span", session.class, task.class, request.URL);
        return;
    }

    if (self.baseEndpointStr.length > 0 && [request.URL.absoluteString hasPrefix:self.baseEndpointStr]) {
        BSGLogTrace(@"NetworkInstrumentation.URLSession:%@ task:%@ didFinishCollectingMetrics for url [%@]: Has base endpoint %@ so not recording span", session.class, task.class, request.URL, self.baseEndpointStr);
        return;
    }

    auto span = self.repository->getInstrumentationState(task).overallSpan;
    if (!span) {
        BSGLogTrace(@"NetworkInstrumentation.URLSession:%@ task:%@ didFinishCollectingMetrics for url [%@]: No associated task found", session.class, task.class, request.URL);
        return;
    }

    BSGLogTrace(@"NetworkInstrumentation.URLSession:%@ task:%@ didFinishCollectingMetrics for url [%@]: Ending span with time %@", session.class, task.class, request.URL, metrics.taskInterval.endDate);

    [span internalSetMultipleAttributes:self.spanAttributesProvider->networkSpanAttributes(nil, task, metrics, errorFromGetRequest)];
    [span endWithEndTime:metrics.taskInterval.endDate];
    self.repository->setInstrumentationState(task, nil);
}

@end
