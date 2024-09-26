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
@property(nonatomic, readonly) NSDate * _Nullable startTime;

// The context that this span is to be a child of, or nil if this will be a top-level span.
@property(nonatomic, readonly) BugsnagPerformanceSpanContext * _Nullable parentContext;

// If true, the span will be added to the current context stack.
@property(nonatomic, readonly) BOOL makeCurrentContext;

// If true, this span will be considered "first class" on the dashboard.
@property(nonatomic, readonly) BSGFirstClass firstClass;

// If false, this span will not include frame rendering metrics
@property(nonatomic, readonly) BOOL instrumentRendering;


- (instancetype _Nonnull)setStartTime:(NSDate * _Nullable)startTime;
- (instancetype _Nonnull)setParentContext:(BugsnagPerformanceSpanContext * _Nullable)parentContext;
- (instancetype _Nonnull)setMakeCurrentContext:(BOOL)makeCurrentContext;
- (instancetype _Nonnull)setFirstClass:(BSGFirstClass)firstClass;
- (instancetype _Nonnull)setInstrumentRendering:(BOOL)instrumentRendering;

- (instancetype _Nonnull)clone;

@end
