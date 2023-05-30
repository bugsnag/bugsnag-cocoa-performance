//
//  BugsnagPerformanceSpanOptions.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 15.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

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
@property(nonatomic,readwrite,strong) BugsnagPerformanceSpan *parentContext;

// If true, the span will be added to the current context stack.
@property(nonatomic,readwrite) BOOL makeCurrentContext;

// If true, this span will be considered "first class" on the dashboard.
@property(nonatomic,readwrite) BSGFirstClass firstClass;

+ (instancetype)optionsWithStartTime:(NSDate *)starttime
                       parentContext:(BugsnagPerformanceSpan *)parentContext
                  makeCurrentContext:(BOOL)makeCurrentContext
                          firstClass:(BSGFirstClass)firstClass;

- (instancetype)initWithStartTime:(NSDate *)starttime
                    parentContext:(BugsnagPerformanceSpan *)parentContext
               makeCurrentContext:(BOOL)makeCurrentContext
                       firstClass:(BSGFirstClass)firstClass;

- (instancetype)clone;

@end
