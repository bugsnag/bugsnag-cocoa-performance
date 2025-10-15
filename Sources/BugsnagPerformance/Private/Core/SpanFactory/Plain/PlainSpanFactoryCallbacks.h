//
//  PlainSpanFactoryCallbacks.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 15/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "../../Span/BugsnagPerformanceSpan+Private.h"

typedef void (^OnSpanStartCallback)(BugsnagPerformanceSpan * _Nonnull,
                                    const SpanOptions &options);

@interface PlainSpanFactoryCallbacks : NSObject

@property (nonatomic, nullable) OnSpanStartCallback onSpanStarted;
@property (nonatomic, nullable) SpanLifecycleCallback onSpanEndSet;
@property (nonatomic, nullable) SpanLifecycleCallback onSpanClosed;
@property (nonatomic, nullable) SpanBlockedCallback onSpanBlocked;
@property (nonatomic, nullable) SpanLifecycleCallback onSpanCancelled;

@end
