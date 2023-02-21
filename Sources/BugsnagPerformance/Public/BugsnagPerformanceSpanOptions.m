//
//  BugsnagPerformanceSpanOptions.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 15.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpanOptions.h>

@implementation BugsnagPerformanceSpanOptions

+ (instancetype)optionsWithStartTime:(NSDate *)startTime
                       parentContext:(id<BugsnagPerformanceSpanContext>)parentContext
                  makeContextCurrent:(BOOL)makeContextCurrent
                        isFirstClass:(BSGFirstClass)isFirstClass {
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
                      isFirstClass:BSGFirstClassUnset];
}

- (instancetype)initWithStartTime:(NSDate *)startTime
                    parentContext:(id<BugsnagPerformanceSpanContext>)parentContext
               makeContextCurrent:(BOOL)makeContextCurrent
                     isFirstClass:(BSGFirstClass)isFirstClass {
    if ((self = [super init])) {
        _startTime = startTime;
        _parentContext = parentContext;
        _makeContextCurrent = makeContextCurrent;
        _isFirstClass = isFirstClass;
    }
    return self;
}

- (instancetype)clone {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    return [BugsnagPerformanceSpanOptions optionsWithStartTime:_startTime
                                                 parentContext:_parentContext
                                            makeContextCurrent:_makeContextCurrent
                                                  isFirstClass:_isFirstClass];
}

@end
