//
//  BugsnagPerformanceSpanOptions.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 15.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "../Private/BugsnagPerformanceSpanOptions+Private.h"

@implementation BugsnagPerformanceSpanOptions

- (instancetype)initWithStartTime:(NSDate *)startTime
                    parentContext:(id<BugsnagPerformanceSpanContext>)parentContext
               makeContextCurrent:(BOOL)makeContextCurrent
                     isFirstClass:(BOOL)isFirstClass
                 wasFirstClassSet:(BOOL)wasFirstClassSet {
    if ((self = [super init])) {
        _startTime = startTime;
        _parentContext = parentContext;
        _makeContextCurrent = makeContextCurrent;
        _isFirstClass = isFirstClass;
        _wasFirstClassSet = wasFirstClassSet;
    }
    return self;
}

- (void)setIsFirstClass:(BOOL)isFirstClass {
    _isFirstClass = isFirstClass;
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    _wasFirstClassSet = true;
}

+ (instancetype)optionsWithStartTime:(NSDate *)startTime
                       parentContext:(id<BugsnagPerformanceSpanContext>)parentContext
                  makeContextCurrent:(BOOL)makeContextCurrent
                        isFirstClass:(BOOL)isFirstClass {
    return [[self alloc] initWithStartTime:startTime
                             parentContext:parentContext
                        makeContextCurrent:makeContextCurrent
                              isFirstClass:isFirstClass];
}

- (instancetype)init {
    // These defaults must match the defaults in SpanOptions.h
    return [self initWithStartTime:nil
                     parentContext:nil
                makeContextCurrent:true
                      isFirstClass:false
                  wasFirstClassSet:false];
}

- (instancetype)initWithStartTime:(NSDate *)startTime
                    parentContext:(id<BugsnagPerformanceSpanContext>)parentContext
               makeContextCurrent:(BOOL)makeContextCurrent
                     isFirstClass:(BOOL)isFirstClass {
    return [self initWithStartTime:startTime
                     parentContext:parentContext
                makeContextCurrent:makeContextCurrent
                      isFirstClass:isFirstClass
                  wasFirstClassSet:false];
}

- (instancetype)clone {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    return [[BugsnagPerformanceSpanOptions alloc] initWithStartTime:_startTime
                                                      parentContext:_parentContext
                                                 makeContextCurrent:_makeContextCurrent
                                                       isFirstClass:_isFirstClass
                                                   wasFirstClassSet:_wasFirstClassSet];
}

@end
