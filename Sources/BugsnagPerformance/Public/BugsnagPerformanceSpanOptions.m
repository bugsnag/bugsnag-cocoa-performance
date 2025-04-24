//
//  BugsnagPerformanceSpanOptions.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 15.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanContext.h>
#import <BugsnagPerformance/BugsnagPerformanceSpanOptions.h>

@implementation BugsnagPerformanceSpanMetricsOptions

- (instancetype)initWithRendering:(BSGTriState)rendering
                              cpu:(BSGTriState)cpu
                           memory:(BSGTriState)memory {
    if ((self = [super init])) {
        _rendering = rendering;
        _cpu = cpu;
        _memory = memory;
    }
    return self;
}

- (instancetype)init {
    return [self initWithRendering:BSGTriStateUnset cpu:BSGTriStateUnset memory:BSGTriStateUnset];
}

- (instancetype)clone {
    return [[BugsnagPerformanceSpanMetricsOptions alloc] initWithRendering:self.rendering
                                                                       cpu:self.cpu
                                                                    memory:self.memory];
}

@end

@interface BugsnagPerformanceSpanOptions()
@property(nonatomic,strong) NSDate *startTime_;
@property(nonatomic,strong) BugsnagPerformanceSpanContext *parentContext_;
@property(nonatomic) BOOL makeCurrentContext_;
@property(nonatomic) BSGTriState firstClass_;
@end

@implementation BugsnagPerformanceSpanOptions

@synthesize startTime_ = _startTime;
@synthesize parentContext_ = _parentContext;
@synthesize makeCurrentContext_ = _makeCurrentContext;
@synthesize firstClass_ = _firstClass;

- (instancetype)init {
    // These defaults must match the defaults in SpanOptions.h
    return [self initWithStartTime:nil
                     parentContext:nil
                makeCurrentContext:true
                        firstClass:BSGTriStateUnset
                    metricsOptions:[BugsnagPerformanceSpanMetricsOptions new]];
}

- (instancetype)initWithStartTime:(NSDate *)startTime
                    parentContext:(BugsnagPerformanceSpanContext *)parentContext
               makeCurrentContext:(BOOL)makeCurrentContext
                       firstClass:(BSGTriState)firstClass
                   metricsOptions:(BugsnagPerformanceSpanMetricsOptions *)metricsOptions {
    if ((self = [super init])) {
        _startTime = startTime;
        _parentContext = parentContext;
        _makeCurrentContext = makeCurrentContext;
        _firstClass = firstClass;
        _metricsOptions = metricsOptions;
    }
    return self;
}

- (NSDate *)startTime {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    return _startTime;
}

- (BugsnagPerformanceSpanContext *)parentContext {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    return _parentContext;
}

- (BOOL)makeCurrentContext {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    return _makeCurrentContext;
}

- (BSGTriState)firstClass {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    return _firstClass;
}

- (BSGTriState)instrumentRendering {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    return _metricsOptions.rendering;
}

- (instancetype)setStartTime:(NSDate *)startTime {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    _startTime = startTime;
    return self;
}

- (instancetype)setParentContext:(BugsnagPerformanceSpanContext *)parentContext {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    _parentContext = parentContext;
    return self;
}

- (instancetype)setMakeCurrentContext:(BOOL)makeCurrentContext {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    _makeCurrentContext = makeCurrentContext;
    return self;
}

- (instancetype)setFirstClass:(BSGTriState)firstClass {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    _firstClass = firstClass;
    return self;
}

- (instancetype _Nonnull)setInstrumentRendering:(BSGTriState)instrumentRendering {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    _metricsOptions.rendering = instrumentRendering;
    return self;
}

- (instancetype)clone {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    return [[BugsnagPerformanceSpanOptions alloc] initWithStartTime:_startTime
                                                      parentContext:_parentContext
                                                 makeCurrentContext:_makeCurrentContext
                                                         firstClass:_firstClass
                                                     metricsOptions:[self.metricsOptions clone]];
}

@end
