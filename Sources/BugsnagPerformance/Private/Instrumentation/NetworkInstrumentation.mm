//
//  NetworkInstrumentation.m
//  
//
//  Created by Karl Stenerud on 14.10.22.
//

#import "NetworkInstrumentation.h"
#import "NetworkInstrumentation/NSURLSession+Instrumentation.h"

#import "../Span.h"

#import <objc/runtime.h>

#if 0
#define Trace NSLog
#else
#define Trace(...)
#endif

using namespace bugsnag;

@interface BSGURLSessionPerformanceDelegate () <NSURLSessionTaskDelegate>

@property(readonly,nonatomic) std::shared_ptr<Tracer> tracer;
@property(readonly,strong,nonatomic) NSString * _Nonnull baseEndpointStr;

- (instancetype) initWithTracer:(std::shared_ptr<Tracer>)tracer  baseEndpoint:(NSURL * _Nonnull)baseEndpoint;

@end

@implementation BSGURLSessionPerformanceDelegate

- (instancetype) initWithTracer:(std::shared_ptr<Tracer>)tracer baseEndpoint:(NSURL * _Nonnull)baseEndpoint {
    if ((self = [super init]) != nil) {
        _tracer = tracer;
        _baseEndpointStr = (NSString * _Nonnull)baseEndpoint.absoluteString;
    }
    return self;
}

- (void)URLSession:(__unused NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics
API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {

    if (self.baseEndpointStr.length > 0 && [task.originalRequest.URL.absoluteString hasPrefix:self.baseEndpointStr]) {
        return;
    }

    self.tracer->reportNetworkSpan(task, metrics);
}

@end

void NetworkInstrumentation::configure(BugsnagPerformanceConfiguration *config) noexcept {
    isEnabled = config.autoInstrumentNetworkRequests;
    delegate_ = [[BSGURLSessionPerformanceDelegate alloc] initWithTracer:tracer_ baseEndpoint:(NSURL * _Nonnull)config.endpoint];
}

void
NetworkInstrumentation::start() noexcept {
    if (!isEnabled) {
        return;
    }

    Trace(@"NetworkInstrumentation::start()");
    bsg_installNSURLSessionPerformance(delegate_);
}
