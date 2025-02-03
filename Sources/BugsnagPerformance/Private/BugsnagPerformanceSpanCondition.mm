//
//  SpanCondition.m
//  BugsnagPerformance-iOS
//
//  Created by Robert B on 15/01/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BugsnagPerformanceSpanCondition+Private.h"

typedef NS_ENUM(uint8_t, BSGSpanConditionState) {
    BSGSpanConditionStateInitial = 0,
    BSGSpanConditionStateUpgraded = 1,
    BSGSpanConditionStateClosed = 2,
    BSGSpanConditionStateCancelled = 3,
};

@interface SpanConditionIdProvider: NSObject

@property (atomic) SpanConditionId conditionId;

+ (instancetype)sharedInstance;

- (SpanConditionId)next;

@end

@implementation SpanConditionIdProvider

+ (instancetype)sharedInstance {
    static id sharedInstance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _conditionId = 0;
    }
    return self;
}

- (SpanConditionId)next {
    @synchronized (self) {
        return self.conditionId++;
    }
}

@end

@interface BugsnagPerformanceSpanCondition ()

@property (nonatomic) SpanConditionId conditionId_;
@property (nonatomic) BSGSpanConditionState state;
@property (nonatomic) SpanConditionClosedCallback onClosedCallback;
@property (nonatomic) SpanConditionUpgradedCallback onUpgradedCallback;
@property (nonatomic) NSMutableArray<SpanConditionDeavtivatedCallback> *onDeactivatedCallbacks;

@end

@implementation BugsnagPerformanceSpanCondition

+ (instancetype)conditionWithSpan:(BugsnagPerformanceSpan *)span
                 onClosedCallback:(SpanConditionClosedCallback)onClosedCallback
               onUpgradedCallback:(SpanConditionUpgradedCallback)onUpgradedCallback {
    return [[self alloc] initWithId:[[SpanConditionIdProvider sharedInstance] next] 
                               span:span
                   onClosedCallback:onClosedCallback
                 onUpgradedCallback:onUpgradedCallback];
}

- (instancetype)initWithId:(SpanConditionId)conditionId
                      span:(BugsnagPerformanceSpan *)span
          onClosedCallback:(SpanConditionClosedCallback)onClosedCallback
        onUpgradedCallback:(SpanConditionUpgradedCallback)onUpgradedCallback {
    self = [super init];
    if (self) {
        _conditionId_ = conditionId;
        _state = BSGSpanConditionStateInitial;
        _span = span;
        _onClosedCallback = onClosedCallback;
        _onUpgradedCallback = onUpgradedCallback;
        _onDeactivatedCallbacks = [NSMutableArray new];
    }
    return self;
}

- (BOOL)isActive {
    @synchronized (self) {
        return self.state == BSGSpanConditionStateInitial || self.state == BSGSpanConditionStateUpgraded;
    }
}

- (SpanConditionId)conditionId {
    return self.conditionId_;
}

- (void)closeWithEndTime:(NSDate *)endTime {
    @synchronized (self) {
        if (self.state == BSGSpanConditionStateClosed || self.state == BSGSpanConditionStateCancelled) {
            return;
        }
        self.state = BSGSpanConditionStateClosed;
    }
    self.onClosedCallback(self, [endTime timeIntervalSinceReferenceDate]);
    [self didDeactivate];
}

- (BugsnagPerformanceSpanContext *)upgrade {
    @synchronized (self) {
        if (self.state != BSGSpanConditionStateInitial) {
            return nil;
        }
        self.state = BSGSpanConditionStateUpgraded;
    }
    return self.onUpgradedCallback(self);
}

- (void)cancel {
    @synchronized (self) {
        if (self.state == BSGSpanConditionStateCancelled || self.state == BSGSpanConditionStateClosed) {
            return;
        }
        self.state = BSGSpanConditionStateCancelled;
    }
    [self didDeactivate];
}

- (void)didTimeout {
    @synchronized (self) {
        if (self.state == BSGSpanConditionStateUpgraded) {
            return;
        }
    }
    [self cancel];
}

- (void)addOnDeactivatedCallback:(SpanConditionDeavtivatedCallback)onDeactivated {
    @synchronized (self) {
        [self.onDeactivatedCallbacks addObject:onDeactivated];
    }
}

- (void)didDeactivate {
    NSArray *callbacks;
    @synchronized (self) {
        callbacks = [self.onDeactivatedCallbacks copy];
    }
    for (SpanConditionDeavtivatedCallback callback in callbacks) {
        callback(self);
    }
}

@end
