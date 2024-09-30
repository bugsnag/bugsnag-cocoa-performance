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

@interface BugsnagPerformanceSpanOptions()
@property(nonatomic,strong) NSDate *startTime_;
@property(nonatomic,strong) BugsnagPerformanceSpanContext *parentContext_;
@property(nonatomic) BOOL makeCurrentContext_;
@property(nonatomic) BSGFirstClass firstClass_;
@property(nonatomic) BSGInstrumentRendering instrumentRendering_;
@end

@implementation BugsnagPerformanceSpanOptions

@synthesize startTime_ = _startTime;
@synthesize parentContext_ = _parentContext;
@synthesize makeCurrentContext_ = _makeCurrentContext;
@synthesize firstClass_ = _firstClass;
@synthesize instrumentRendering_ = _instrumentRendering;

- (instancetype)init {
    // These defaults must match the defaults in SpanOptions.h
    return [self initWithStartTime:nil
                     parentContext:nil
                makeCurrentContext:true
                        firstClass:BSGFirstClassUnset
               instrumentRendering:BSGInstrumentRenderingUnset];
}

- (instancetype)initWithStartTime:(NSDate *)startTime
                    parentContext:(BugsnagPerformanceSpanContext *)parentContext
               makeCurrentContext:(BOOL)makeCurrentContext
                       firstClass:(BSGFirstClass)firstClass
              instrumentRendering:(BSGInstrumentRendering)instrumentRendering {
    if ((self = [super init])) {
        _startTime = startTime;
        _parentContext = parentContext;
        _makeCurrentContext = makeCurrentContext;
        _firstClass = firstClass;
        _instrumentRendering = instrumentRendering;
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

- (BSGFirstClass)firstClass {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    return _firstClass;
}

- (BSGInstrumentRendering)instrumentRendering {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    return _instrumentRendering;
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

- (instancetype)setFirstClass:(BSGFirstClass)firstClass {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    _firstClass = firstClass;
    return self;
}

- (instancetype _Nonnull)setInstrumentRendering:(BSGInstrumentRendering)instrumentRendering {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    _instrumentRendering = instrumentRendering;
    return self;
}

- (instancetype)clone {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    return [[BugsnagPerformanceSpanOptions alloc] initWithStartTime:_startTime
                                                      parentContext:_parentContext
                                                 makeCurrentContext:_makeCurrentContext
                                                         firstClass:_firstClass
                                                instrumentRendering:_instrumentRendering];
}

@end
