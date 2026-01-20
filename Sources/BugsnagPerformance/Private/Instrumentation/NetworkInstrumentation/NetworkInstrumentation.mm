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
    lifecycleHandler_->onInstrumentationConfigured(isEnabled_, networkRequestCallback_);
}

void NetworkInstrumentation::preStartSetup() noexcept {
    [delegate_ preStartSetup];
}

void NetworkInstrumentation::start() noexcept {
    BSGLogTrace(@"NetworkInstrumentation::start()");
    [delegate_ start];
}

void NetworkInstrumentation::NSURLSessionTask_resume(NSURLSessionTask *task) noexcept {
    if (!isEnabled_) {
        BSGLogTrace(@"NetworkInstrumentation::NSURLSessionTask_resume: Not enabled (task was %@)", task.class);
        return;
    }
    lifecycleHandler_->onTaskResume(task);
}
