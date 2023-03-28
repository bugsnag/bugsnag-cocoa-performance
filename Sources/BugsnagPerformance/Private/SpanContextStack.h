//
//  SpanContextStack.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 17.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import <BugsnagPerformance/BugsnagPerformanceSpanContext.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Maintains a context stack per activity.
 * All operations will affect only the stack in the current activity.
 */
@interface SpanContextStack : NSObject

+ (instancetype)current;

- (void)push:(id<BugsnagPerformanceSpanContext>)context;
- (id<BugsnagPerformanceSpanContext> _Nullable)context;

- (BOOL)hasSpanWithAttribute:(NSString *)attribute value:(NSString *)value;

// Accessible for testing only.
@property(nonatomic,readwrite,strong) NSMutableDictionary<NSNumber *, NSPointerArray *> *stacks;

@end

NS_ASSUME_NONNULL_END
