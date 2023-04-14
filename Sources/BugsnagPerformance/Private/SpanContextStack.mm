//
//  SpanContextStack.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 17.02.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "SpanContextStack+Private.h"
#import "BugsnagPerformanceSpan+Private.h"
#import <os/activity.h>
#import <objc/runtime.h>

/* Implementation note:
 *
 * This code is full of subtleties because it touches numerous runtime aspects that
 * overlap in subtle ways:
 * - Threading
 * - Activity Tracing
 * - Dispatch Queues
 * - ARC (automatic reference counting)
 *
 * Span contexts can sometimes cross thread boundaries when a dispatch queue automatically
 * moves the work onto one of its dispatch queue threads. This impacts the thread safety
 * of any span context stack implementation because it voids any single-thread-access
 * guarantees like you'd get from a thread-local.
 *
 * Activity scopes are partially managed using Objective-C's ARC to ensure proper cleanup
 * (see ActivityRef) if a span context is dropped. This also requires careful use of
 * @autoreleasepool to ensure that we don't get weird activity scope trees due to
 * threading issues.
 *
 * Associated objects are used to tie an activity scope to a span context as far as ARC
 * is concerned.
 *
 * Activity tracing manages its own stack that we don't have access to, so we must
 * maintain our own mirror and somehow keep it in (eventual) sync.
 *
 * All of this must also be performant because span begin and end are on the hot path.
 */

/**
 * Encapsulates an os_activity_id_t and associated data for use as a map key.
 * Activities can sometimes cross threads (if code passes to a background dispatch queue),
 * so all associated data must come along for the ride.
 */
@interface ActivityRef: NSObject

@property(nonatomic,readwrite,strong) NSNumber *key;
@property(nonatomic,readwrite) os_activity_id_t activityId;
@property(nonatomic,readwrite) struct os_activity_scope_state_s activityState;

@end

@implementation ActivityRef

- (instancetype)init {
    if ((self = [super init])) {
        os_activity_t activity = os_activity_create("BSGSpanContext", OS_ACTIVITY_CURRENT, OS_ACTIVITY_FLAG_DEFAULT);
        _activityId = os_activity_get_identifier(activity, nil);
        _key = [NSNumber numberWithUnsignedLongLong:_activityId];
        os_activity_scope_enter(activity, &_activityState);
    }
    return self;
}

- (void)dealloc {
    os_activity_scope_leave(&_activityState);
}

@end


static const char * const ActivityRefKey = "BSGActivityRef";

@implementation SpanContextStack

+ (instancetype)current {
    static SpanContextStack *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if ((self = [super init])) {
        _stacks = [NSMutableDictionary new];
    }
    return self;
}

static id<BugsnagPerformanceSpanContext> lastObject(NSPointerArray *stack) {
    if (stack.count > 0) {
        return (__bridge id<BugsnagPerformanceSpanContext>)[stack pointerAtIndex:stack.count-1];
    }
    return nil;
}

- (void) sweep:(NSPointerArray *)stack {
    @synchronized (stack) {
        while (stack.count > 0) {
            auto context = (__bridge id<BugsnagPerformanceSpanContext>)[stack pointerAtIndex:stack.count-1];
            if (!context.isValid) {
                // Remove the invalid context in multiple steps:

                // Remove the context from our current stack.
                [stack removePointerAtIndex:stack.count-1];

                // Clear the activity ref so that it gets deallocated at the end of the autoreleasepool.
                // Deallocation will cause the ref to leave the current activity.
                NSNumber *key = nil;
                @autoreleasepool {
                    if (context != nil) {
                        ActivityRef *ref = objc_getAssociatedObject(context, ActivityRefKey);
                        objc_setAssociatedObject(context, ActivityRefKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                        key = ref.key;
                    }
                }

                // Remove this activity's reference to the stack
                if (key != nil) {
                    @synchronized (self.stacks) {
                        self.stacks[key] = nil;
                    }
                }
            } else {
                break;
            }
        }
    }
}

- (void)push:(id<BugsnagPerformanceSpanContext>)context {
    NSPointerArray *stack = [self currentStackOrNew];

    @synchronized (stack) {
        // Start a new activity scope under the current scope (or as top level if none exists).
        ActivityRef *ref = [ActivityRef new];

        // Store it in the context so that we can find it again.
        // This also ensures that ref will live at most until context dies since the stack uses weak references.
        objc_setAssociatedObject(context, ActivityRefKey, ref, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        // Save a reference to this activity's stack so that we can find it again.
        @synchronized (self.stacks) {
            self.stacks[ref.key] = stack;
        }
        
        // Add the new context to the current activity's context stack.
        [stack addPointer:(__bridge void *)context];
    }
}

- (NSPointerArray *)currentStackOrNew {
    os_activity_id_t activityId = os_activity_get_identifier(OS_ACTIVITY_CURRENT, nil);
    NSNumber *key = [NSNumber numberWithUnsignedLongLong:activityId];
    NSPointerArray *stack = nil;
    @synchronized (self.stacks) {
        stack = self.stacks[key];
        if (stack == nil) {
            stack = [NSPointerArray weakObjectsPointerArray];
            if (activityId != 0) {
                self.stacks[key] = stack;
            }
        }
    }
    [self sweep:stack];
    return stack;
}

- (id<BugsnagPerformanceSpanContext> _Nullable)context {
    NSPointerArray *stack = [self currentStackOrNew];
    return lastObject(stack);
}

- (BOOL)hasSpanWithAttribute:(NSString *)attribute value:(NSString *)value {
    NSPointerArray *stack = [self currentStackOrNew];
    @synchronized (stack) {
        const auto count = stack.count;
        for (NSUInteger i = 0; i < count; i++) {
            id entry = (__bridge id)[stack pointerAtIndex:i];
            if ([entry isKindOfClass:[BugsnagPerformanceSpan class]]) {
                auto span = (BugsnagPerformanceSpan *)entry;
                if (span.isValid) {
                    if ([span hasAttribute:attribute withValue:value]) {
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}

- (void)clearForUnitTests {
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    _stacks = [NSMutableDictionary new];
}

@end
