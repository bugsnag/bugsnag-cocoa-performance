//
//  SpanCondition.m
//  BugsnagPerformance-iOS
//
//  Created by Robert Bartoszewski on 15/01/2025.
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
        switch (self.state) {
            case BSGSpanConditionStateClosed:
            case BSGSpanConditionStateCancelled:
                return;
            case BSGSpanConditionStateInitial:
            case BSGSpanConditionStateUpgraded:
                self.state = BSGSpanConditionStateClosed;
                break;
        }
    }
    self.onClosedCallback(self, [endTime timeIntervalSinceReferenceDate]);
    [self didDeactivate];
}

- (BugsnagPerformanceSpanContext *)upgrade {
    @synchronized (self) {
        switch (self.state) {
            case BSGSpanConditionStateClosed:
            case BSGSpanConditionStateCancelled:
            case BSGSpanConditionStateUpgraded:
                return nil;
            case BSGSpanConditionStateInitial:
                self.state = BSGSpanConditionStateUpgraded;
                break;
        }
    }
    return self.onUpgradedCallback(self);
}

- (void)cancel {
    @synchronized (self) {
        switch (self.state) {
            case BSGSpanConditionStateClosed:
            case BSGSpanConditionStateCancelled:
                return;
            case BSGSpanConditionStateInitial:
            case BSGSpanConditionStateUpgraded:
                self.state = BSGSpanConditionStateCancelled;
                break;
        }
    }
    [self didDeactivate];
}

- (void)didTimeout {
    @synchronized (self) {
        switch (self.state) {
            case BSGSpanConditionStateClosed:
            case BSGSpanConditionStateCancelled:
            case BSGSpanConditionStateUpgraded:
                return;
            case BSGSpanConditionStateInitial:
                break;
        }
        [self cancel];
    }
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
