//
//  BugsnagPerformanceNamedSpansPlugin.m
//  BugsnagPerformanceNamedSpans
//
//  Created by Yousif Ahmed on 22/07/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <BugsnagPerformanceNamedSpans/BugsnagPerformanceNamedSpansPlugin.h>
#import <BugsnagPerformanceNamedSpans/BugsnagPerformanceNamedSpanQuery.h>
#import <BugsnagPerformance/BugsnagPerformancePluginContext.h>
#import <BugsnagPerformance/BugsnagPerformancePriority.h>
#import "../Private/BugsnagPerformanceNamedSpansPlugin+Private.h"
#import "../Private/NamedSpansStore.h"

static const NSTimeInterval kSpanTimeoutInterval = 600; // 10 minutes
static const NSTimeInterval kSpanSweepInterval = 60; // 1 minute

using namespace bugsnag;

@interface BugsnagPerformanceSpan () <BugsnagPerformanceSpanControl>

@end

@interface BugsnagPerformanceNamedSpansPlugin ()

@property (nonatomic, assign, readonly) std::shared_ptr<NamedSpansStore> store;

@end

@implementation BugsnagPerformanceNamedSpansPlugin

#pragma mark - Initialization

- (instancetype)init {
    return [self initWithTimeoutInterval:kSpanTimeoutInterval sweepInterval:kSpanSweepInterval];
}

- (instancetype)initWithTimeoutInterval:(NSTimeInterval)timeoutInterval
                          sweepInterval:(NSTimeInterval)sweepInterval {
    if ((self = [super init])) {
        _store = std::make_shared<NamedSpansStore>(timeoutInterval,
                                                   sweepInterval);
    }
    return self;
}

#pragma mark BugsnagPerformancePlugin

- (void)installWithContext:(BugsnagPerformancePluginContext *)context {
    // Add spans to the cache when started
    __weak BugsnagPerformanceNamedSpansPlugin *weakSelf = self;
    BugsnagPerformanceSpanStartCallback spanStartCallback = ^(BugsnagPerformanceSpan *span) {
        __strong BugsnagPerformanceNamedSpansPlugin *strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        
        [strongSelf didStartSpan:span];
    };
    
    // Remove spans from the cache when ended
    BugsnagPerformanceSpanEndCallback spanEndCallback = ^(BugsnagPerformanceSpan *span) {
        __strong BugsnagPerformanceNamedSpansPlugin *strongSelf = weakSelf;
        if (strongSelf == nil) {
            return YES;
        }
        
        return [strongSelf didEndSpan:span];;
    };
    
    [context addOnSpanStartCallback:spanStartCallback priority:BugsnagPerformancePriorityHigh];
    [context addOnSpanEndCallback:spanEndCallback priority:BugsnagPerformancePriorityLow];
    [context addSpanControlProvider:self];
    self.store->start();
}

- (void)start {
}

#pragma mark BugsnagPerformanceSpanControlProvider

- (id<BugsnagPerformanceSpanControl>)getSpanControlsWithQuery:(BugsnagPerformanceSpanQuery *)query {
    if ([query isKindOfClass:[BugsnagPerformanceNamedSpanQuery class]]) {
        NSString *spanName = [query getAttributeWithName:@"name"];
        return self.store->getSpan(spanName);
    }
    return nil;
}

#pragma mark Private

- (void)didStartSpan:(BugsnagPerformanceSpan *)span {
    self.store->add(span);
}

- (BOOL)didEndSpan:(BugsnagPerformanceSpan *)span {
    self.store->remove(span);
    return YES;
}

@end
