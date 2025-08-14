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

static const NSTimeInterval kSpanTimeoutInterval = 600; // 10 minutes

@interface BugsnagPerformanceNamedSpansPlugin ()

@property (nonatomic, strong) NSMutableDictionary *spansByName;

@end

@implementation BugsnagPerformanceNamedSpansPlugin

#pragma mark - Initialization

- (instancetype)init {
    return [self initWithTimeoutInterval:kSpanTimeoutInterval];
}

- (instancetype)initWithTimeoutInterval:(NSTimeInterval)timeoutInterval {
    if ((self = [super init])) {
        _timeoutInterval = timeoutInterval;
        _spansByName = [NSMutableDictionary new];
        _spanTimeoutTimers = std::make_shared<std::unordered_map<void *, dispatch_source_t>>();
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
}

- (void)start {
}

#pragma mark BugsnagPerformanceSpanControlProvider

- (id<BugsnagPerformanceSpanControl>)getSpanControlsWithQuery:(BugsnagPerformanceSpanQuery *)query {
    if ([query isKindOfClass:[BugsnagPerformanceNamedSpanQuery class]]) {
        NSString *spanName = [query getAttributeWithName:@"name"];
        @synchronized (self) {
            return self.spansByName[spanName];
        }
    }
    return nil;
}

#pragma mark Private

- (void)didStartSpan:(BugsnagPerformanceSpan *)span {
    @synchronized (self) {
        BugsnagPerformanceSpan *existingSpan = self.spansByName[span.name];
        if (existingSpan) {
            // If a span with the same name already exists, cancel the associated timeout
            [self cancelSpanTimeout:existingSpan];
        }
        
        self.spansByName[span.name] = span;
        
        // Add timeout to remove the span from the cache if not ended
        void *key = (__bridge void *)span;
        dispatch_source_t timer = [self createSpanTimeoutTimer:span];
        (*self.spanTimeoutTimers)[key] = timer;
    }
}

- (BOOL)didEndSpan:(BugsnagPerformanceSpan *)span {
    @synchronized (self) {
        // Remove span from cache if it exists
        if ([self.spansByName objectForKey:span.name] == span) {
            [self.spansByName removeObjectForKey:span.name];
        }

        [self cancelSpanTimeout:span];
    }
    return YES;
}

- (dispatch_source_t)createSpanTimeoutTimer:(BugsnagPerformanceSpan *)span {
    __weak BugsnagPerformanceNamedSpansPlugin *weakSelf = self;
    
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                                     dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
    
    dispatch_source_set_timer(timer,
                             dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.timeoutInterval * NSEC_PER_SEC)),
                             DISPATCH_TIME_FOREVER,
                             0);
    
    dispatch_source_set_event_handler(timer, ^{
        [weakSelf didEndSpan:span];
    });
    
    dispatch_resume(timer);
    return timer;
}

- (void)cancelSpanTimeout:(BugsnagPerformanceSpan *)span {
    void *key = (__bridge void *)span;
    auto it = self.spanTimeoutTimers->find(key);
    if (it != self.spanTimeoutTimers->end()) {
        dispatch_source_cancel(it->second);
        self.spanTimeoutTimers->erase(it);
    }
}

@end
