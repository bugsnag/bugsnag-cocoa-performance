//
//  BSGURLSessionPerformanceDelegate.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 01/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "BSGURLSessionPerformanceDelegate.h"

using namespace bugsnag;

@interface BSGURLSessionPerformanceDelegate ()

@property(readwrite,nonatomic) BOOL isEnabled;
@property(readonly,nonatomic) std::shared_ptr<NetworkLifecycleHandler> lifecycleHandler;
@property(readwrite,strong,nonatomic) NSString *baseEndpointStr;

@end

@implementation BSGURLSessionPerformanceDelegate

- (instancetype) initWithLifecycleHandler:(std::shared_ptr<NetworkLifecycleHandler>)lifecycleHandler {
    if ((self = [super init]) != nil) {
        _lifecycleHandler = lifecycleHandler;
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

    self.lifecycleHandler->onTaskDidFinishCollectingMetrics(task,
                                                            metrics,
                                                            self.baseEndpointStr);
}

@end
