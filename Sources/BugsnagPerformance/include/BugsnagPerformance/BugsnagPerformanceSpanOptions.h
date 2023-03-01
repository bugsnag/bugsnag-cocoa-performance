//
//  BugsnagPerformanceSpanOptions.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 15.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpanContext.h>

typedef NS_ENUM(uint8_t, BSGFirstClass) {
    BSGFirstClassNo = 0,
    BSGFirstClassYes = 1,
    BSGFirstClassUnset = 2,
};

// Span options allow the user to affect how spans are created.
OBJC_EXPORT
@interface BugsnagPerformanceSpanOptions: NSObject

// The time that this span is deemed to have started.
@property(nonatomic,readwrite,strong) NSDate *startTime;

// The context that this span is to be a child of, or nil if this will be a top-level span.
@property(nonatomic,readwrite,strong) id<BugsnagPerformanceSpanContext> parentContext;

// If true, the span will be added to the current context stack.
@property(nonatomic,readwrite) BOOL makeContextCurrent;

// If true, this span will be considered "first class" on the dashboard.
@property(nonatomic,readwrite) BSGFirstClass isFirstClass;

+ (instancetype)optionsWithStartTime:(NSDate *)starttime
                       parentContext:(id<BugsnagPerformanceSpanContext>)parentContext
                  makeContextCurrent:(BOOL)makeContextCurrent
                        isFirstClass:(BSGFirstClass)isFirstClass;

- (instancetype)initWithStartTime:(NSDate *)starttime
                    parentContext:(id<BugsnagPerformanceSpanContext>)parentContext
               makeContextCurrent:(BOOL)makeContextCurrent
                     isFirstClass:(BSGFirstClass)isFirstClass;

- (instancetype)clone;

@end
