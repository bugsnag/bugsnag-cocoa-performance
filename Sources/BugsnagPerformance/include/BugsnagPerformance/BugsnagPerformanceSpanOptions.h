//
//  BugsnagPerformanceSpanOptions.h
//  BugsnagPerformance
//
//  Created by Karl Stenerud on 15.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpanContext.h>

typedef NS_ENUM(uint8_t, BSGTriState) {
    BSGTriStateNo = 0,
    BSGTriStateYes = 1,
    BSGTriStateUnset = 2,
};

@interface BugsnagPerformanceSpanMetricsOptions : NSObject

/**
 * No = never include these metrics
 * Yes = Always include these metrics, as long as the corresponding enabledMetrics configuration option is on
 * Unset = Include metrics only if the span is first class, start and end times were not set when creating/closing
 *       the span and the corresponding enabledMetrics configuration option is on
 * Default: Unset
 */
@property(nonatomic) BSGTriState rendering;

/**
 * No = never include these metrics
 * Yes = Always include these metrics, as long as the corresponding enabledMetrics configuration option is on
 * Unset = Include metrics only if the span is first class and the corresponding enabledMetrics configuration option is on
 * Default: Unset
 */
@property(nonatomic) BSGTriState cpu;

/**
 * No = never include these metrics
 * Yes = Always include these metrics, as long as the corresponding enabledMetrics configuration option is on
 * Unset = Include metrics only if the span is first class and the corresponding enabledMetrics configuration option is on
 * Default: Unset
 */
@property(nonatomic) BSGTriState memory;

- (_Nonnull instancetype)clone;

@end

typedef NS_ENUM(uint8_t, BSGFirstClass) {
    BSGFirstClassNo __attribute__((deprecated)) = BSGTriStateNo,
    BSGFirstClassYes __attribute__((deprecated)) = BSGTriStateYes,
    BSGFirstClassUnset __attribute__((deprecated)) = BSGTriStateUnset,
};

// Affects whether or not a span should include rendering metrics
typedef NS_ENUM(uint8_t, BSGInstrumentRendering) {
    BSGInstrumentRenderingNo __attribute__((deprecated)) = BSGTriStateNo, // Never include rendering metrics
    BSGInstrumentRenderingYes __attribute__((deprecated)) = BSGTriStateYes, // Always include rendering metrics, as long as the autoInstrumentRendering configuration option is on
    BSGInstrumentRenderingUnset __attribute__((deprecated)) = BSGTriStateUnset, // Include rendering metrics only if the span is first class, start and end times were not set when creating/closing the span and the autoInstrumentRendering configuration option is on
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
@property(nonatomic, readonly) BSGTriState firstClass;

@property(nonatomic, readonly) BSGTriState instrumentRendering DEPRECATED_ATTRIBUTE;

@property(nonatomic, strong) BugsnagPerformanceSpanMetricsOptions * _Nonnull metricsOptions;

- (instancetype _Nonnull)setStartTime:(NSDate * _Nullable)startTime;
- (instancetype _Nonnull)setParentContext:(BugsnagPerformanceSpanContext * _Nullable)parentContext;
- (instancetype _Nonnull)setMakeCurrentContext:(BOOL)makeCurrentContext;
- (instancetype _Nonnull)setFirstClass:(BSGTriState)firstClass;
- (instancetype _Nonnull)setInstrumentRendering:(BSGTriState)instrumentRendering DEPRECATED_ATTRIBUTE;

- (instancetype _Nonnull)clone;

@end
