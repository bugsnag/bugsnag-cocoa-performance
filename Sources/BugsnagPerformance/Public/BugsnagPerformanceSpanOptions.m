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
                  makeCurrentContext:(BOOL)makeCurrentContext
                          firstClass:(BSGFirstClass)firstClass {
    return [[self alloc] initWithStartTime:startTime
                             parentContext:parentContext
                        makeCurrentContext:makeCurrentContext
                                firstClass:firstClass];
}

- (instancetype)init {
    // These defaults must match the defaults in SpanOptions.h
    return [self initWithStartTime:nil
                     parentContext:nil
                makeCurrentContext:true
                        firstClass:BSGFirstClassUnset];
}

- (instancetype)initWithStartTime:(NSDate *)startTime
                    parentContext:(id<BugsnagPerformanceSpanContext>)parentContext
               makeCurrentContext:(BOOL)makeCurrentContext
                       firstClass:(BSGFirstClass)firstClass {
    if ((self = [super init])) {
        _startTime = startTime;
        _parentContext = parentContext;
        _makeCurrentContext = makeCurrentContext;
        _firstClass = firstClass;
    }
    return self;
}

- (instancetype)clone {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    return [BugsnagPerformanceSpanOptions optionsWithStartTime:_startTime
                                                 parentContext:_parentContext
                                            makeCurrentContext:_makeCurrentContext
                                                    firstClass:_firstClass];
}

@end
