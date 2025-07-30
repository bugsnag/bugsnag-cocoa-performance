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
#import <map>

static const NSTimeInterval kSpanTimeoutInterval = 600; // 10 minutes

@interface BugsnagPerformanceNamedSpansPlugin () {
    std::map<void *, dispatch_source_t> _spanTimeoutTimers;
}

@property (nonatomic, strong) NSMutableDictionary *spansByName;

@end


@implementation BugsnagPerformanceNamedSpansPlugin

#pragma mark BugsnagPerformancePlugin

#pragma clang diagnostic ignored "-Wdirect-ivar-access"
- (void)installWithContext:(BugsnagPerformancePluginContext *)context {
    self.spansByName = [NSMutableDictionary new];
    
    // Add spans to the cache when started
    __block BugsnagPerformanceNamedSpansPlugin *blockSelf = self;
    BugsnagPerformanceSpanStartCallback spanStartCallback = ^(BugsnagPerformanceSpan *span) {
        @synchronized (blockSelf) {
            blockSelf.spansByName[span.name] = span;
            
            // Add a 10 minute timeout to remove the span from the cache if not ended
            void *key = (__bridge void *)span;
            dispatch_source_t timer = [blockSelf createSpanTimeoutTimer:span];
            blockSelf->_spanTimeoutTimers[key] = timer;
        }
    };
    
    // Remove spans from the cache when ended
    BugsnagPerformanceSpanEndCallback spanEndCallback = ^(BugsnagPerformanceSpan *span) {
        return [blockSelf endNativeSpan:span];
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

- (dispatch_source_t)createSpanTimeoutTimer:(BugsnagPerformanceSpan *)span {
    __weak BugsnagPerformanceNamedSpansPlugin *weakSelf = self;
    
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                                     dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
    
    dispatch_source_set_timer(timer,
                             dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSpanTimeoutInterval * NSEC_PER_SEC)),
                             DISPATCH_TIME_FOREVER,
                             0);
    
    dispatch_source_set_event_handler(timer, ^{
        [weakSelf endNativeSpan:span];
    });
    
    dispatch_resume(timer);
    return timer;
}

#pragma clang diagnostic ignored "-Wdirect-ivar-access"
- (BOOL)endNativeSpan:(BugsnagPerformanceSpan *)span {
    void *key = (__bridge void *)span;

    @synchronized (self) {
        // Remove span from cache if it exists
        if ([self.spansByName objectForKey:span.name] == span) {
            [self.spansByName removeObjectForKey:span.name];
        }

        // Clean up timer for this span
        auto& timerMap = _spanTimeoutTimers;
        auto it = timerMap.find(key);
        if (it != timerMap.end()) {
            dispatch_source_cancel(it->second);
            timerMap.erase(it);
        }
    }
    return YES;
}

@end
