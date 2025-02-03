//
//  BugsnagPerformanceSpan.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "../Private/BugsnagPerformanceSpan+Private.h"
#import "../Private/Utils.h"
#import "../Private/SpanOptions.h"

using namespace bugsnag;

static const uint64_t MONOTONIC_CLOCK_INVALID = 0;
static const NSUInteger MAX_ATTRIBUTE_KEY_LENGTH = 128;

static bool isMonotonicClockValid(uint64_t clock) {
    return clock != MONOTONIC_CLOCK_INVALID;
}

static uint64_t currentMonotonicClockNsecIfUnset(CFAbsoluteTime time) {
    return isCFAbsoluteTimeValid(time) ? MONOTONIC_CLOCK_INVALID : clock_gettime_nsec_np(CLOCK_MONOTONIC);
}

static CFAbsoluteTime currentTimeIfUnset(CFAbsoluteTime time) {
    return isCFAbsoluteTimeValid(time) ? time : CFAbsoluteTimeGetCurrent();
}

@implementation BugsnagPerformanceSpan

- (instancetype)initWithName:(NSString *)name
                     traceId:(TraceId) traceId
                      spanId:(SpanId) spanId
                    parentId:(SpanId) parentId
                   startTime:(CFAbsoluteTime) startAbsTime
                  firstClass:(BSGTriState) firstClass
         attributeCountLimit:(NSUInteger)attributeCountLimit
              metricsOptions:(MetricsOptions)metricsOptions
                onSpanEndSet:(SpanLifecycleCallback) onSpanEndSet
                onSpanClosed:(SpanLifecycleCallback) onSpanClosed
                onSpanBlocked:(SpanBlockedCallback) onSpanBlocked {
    if ((self = [super initWithTraceId:traceId spanId:spanId])) {
        _actuallyStartedAt = CFAbsoluteTimeGetCurrent();
        _actuallyEndedAt = CFABSOLUTETIME_INVALID;
        _startClock = currentMonotonicClockNsecIfUnset(startAbsTime);
        _name = name;
        _parentId = parentId;
        _startAbsTime = currentTimeIfUnset(startAbsTime);
        _startClock = currentMonotonicClockNsecIfUnset(startAbsTime);
        _firstClass = firstClass;
        _onSpanDestroyAction = OnSpanDestroyAbort;
        _onSpanEndSet = onSpanEndSet;
        _onSpanClosed = onSpanClosed;
        _onSpanBlocked = onSpanBlocked;
        _kind = SPAN_KIND_INTERNAL;
        _samplingProbability = 1;
        _state = SpanStateOpen;
        _attributeCountLimit = attributeCountLimit;
        _attributes = [[NSMutableDictionary alloc] init];
        _isMutable = true;
        if (firstClass != BSGTriStateUnset) {
            _attributes[@"bugsnag.span.first_class"] = @(firstClass == BSGTriStateYes);
        }
        _attributes[@"bugsnag.sampling.p"] = @(1.0);
        _metricsOptions = metricsOptions;
        _wasStartOrEndTimeProvided = isCFAbsoluteTimeValid(startAbsTime);
        _activeConditions = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc {
    BSGLogTrace(@"BugsnagPerformanceSpan.dealloc %@", self.name);
    if (self.state == SpanStateOpen && self.onDumped) {
        self.onDumped(self);
    }
    switch(self.onSpanDestroyAction) {
        case OnSpanDestroyAbort:
            BSGLogDebug(@"BugsnagPerformanceSpan.dealloc: for span %@. Action = Abort", self.name);
            [self abortIfOpen];
            break;
        case OnSpanDestroyEnd:
            BSGLogDebug(@"BugsnagPerformanceSpan.dealloc: for span %@. Action = End", self.name);
            [self end];
            break;
        default:
            BSGLogError(@"BugsnagPerformanceSpan.dealloc: for span %@. Unknown action type %d", self.name, self.onSpanDestroyAction);
            break;
    }
}

- (void)abortIfOpen {
    @synchronized (self) {
        BSGLogDebug(@"Span.abortIfOpen: %@: Was open: %d", self.name, self.state == SpanStateOpen);
        if (self.state != SpanStateOpen) {
            // The span has already been closed or aborted.
            return;
        }
        self.state = SpanStateAborted;
    }
    [self sendForProcessing];
}

- (void)abortUnconditionally {
    BSGLogDebug(@"Span.abortUnconditionally: %@: Was open: %d", self.name, self.state == SpanStateOpen);
    self.state = SpanStateAborted;
    [self sendForProcessing];
}

- (void)end {
    [self endWithAbsoluteTime:CFABSOLUTETIME_INVALID];
}

- (void)endWithEndTime:(NSDate *)endTime {
    self.wasStartOrEndTimeProvided |= endTime != nil;
    [self endWithAbsoluteTime:(dateToAbsoluteTime(endTime))];
}

- (void)endWithAbsoluteTime:(CFAbsoluteTime)endTime {
    @synchronized (self) {
        BSGLogDebug(@"Span.endWithAbsoluteTime(%f): %@: Was open: %d", endTime, self.name, self.state == SpanStateOpen);
        if (self.state != SpanStateOpen) {
            // The span has already been closed or aborted.
            return;
        }

        self.actuallyEndedAt = CFAbsoluteTimeGetCurrent();

        // If our start and end times were both "unset", then it's on us to counter any
        // clock skew using the monotonic clock.
        if (isMonotonicClockValid(self.startClock)) {
            auto endClock = currentMonotonicClockNsecIfUnset(endTime);
            if (isMonotonicClockValid(endClock)) {
                // Calculate using signed int so that an end time < start time doesn't overflow.
                endTime = self.startAbsTime + ((double)((int64_t)endClock - (int64_t)self.startClock)) / NSEC_PER_SEC;
            }
        }

        [self markEndAbsoluteTime:endTime];
        self.state = SpanStateEnded;
    }
    [self sendForProcessing];
}

- (void)markEndTime:(NSDate *)endTime {
    [self markEndAbsoluteTime:dateToAbsoluteTime(endTime)];
}

- (void)markEndAbsoluteTime:(CFAbsoluteTime)endTime {
    self.endAbsTime = currentTimeIfUnset(endTime);
    auto onSpanEndSet = self.onSpanEndSet;
    if(onSpanEndSet != nil) {
        onSpanEndSet(self);
    }
}

- (void)sendForProcessing {
    BOOL hasBeenProcessed = false;
    @synchronized (self) {
        hasBeenProcessed = self.hasBeenProcessed;
        self.hasBeenProcessed = true;
    }
    if (!hasBeenProcessed) {
        auto onSpanClosed = self.onSpanClosed;
        if(onSpanClosed != nil) {
            onSpanClosed(self);
        }
    }
    if (self.state == SpanStateOpen) {
        self.state = SpanStateEnded;
    }
    self.isMutable = false;
}

- (void)endOnDestroy {
    self.onSpanDestroyAction = OnSpanDestroyEnd;
}

- (BugsnagPerformanceSpanCondition *_Nullable)blockWithTimeout:(NSTimeInterval)timeout {
    BugsnagPerformanceSpanCondition *condition = self.onSpanBlocked(self, timeout);
    @synchronized (self) {
        if (condition) {
            [self.activeConditions addObject:condition];
            
            __block __weak BugsnagPerformanceSpan *weakSelf = self;
            [condition addOnDeactivatedCallback:^(BugsnagPerformanceSpanCondition *c) {
                __strong BugsnagPerformanceSpan *strongSelf = weakSelf;
                @synchronized (strongSelf) {
                    [strongSelf.activeConditions removeObject:c];
                }
            }];
        }
    }
    return condition;
}

- (BOOL)isBlocked {
    @synchronized (self) {
        for (BugsnagPerformanceSpanCondition *condition in self.activeConditions) {
            if (condition.isActive) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSDate *)startTime {
    return [NSDate dateWithTimeIntervalSinceReferenceDate:self.startAbsTime];
}

- (NSDate *)endTime {
    return [NSDate dateWithTimeIntervalSinceReferenceDate:self.endAbsTime];
}

- (void)updateStartTime:(NSDate *)startTime {
    if (!self.isMutable) {
        BSGLogError(@"Called updateStartTime, but span %llu (%@) is immutable", self.spanId, self.name);
        return;
    }
    self.startAbsTime = dateToAbsoluteTime(startTime);
    self.startClock = currentMonotonicClockNsecIfUnset(self.startAbsTime);
}

- (void)updateName:(NSString *)name {
    if (!self.isMutable) {
        BSGLogError(@"Called updateName, but span %llu (%@) is immutable", self.spanId, self.name);
        return;
    }
    self.name = name;
}

- (BOOL)isValid {
    return self.state == SpanStateOpen;
}

- (void)setAttribute:(NSString *)attributeName withValue:(id)value {
    @synchronized (self) {
        if(value != nil &&
           self.attributes[attributeName] == nil &&
           self.attributes.count >= self.attributeCountLimit) {
            BSGLogError(@"Span attribute \"%@\" in span %llu (%@) was dropped as the number of attributes exceeds the %lu attribute limit set by AttributeCountLimit.", attributeName, self.spanId, self.name, (unsigned long)self.attributeCountLimit);
            return;
        }
        if(attributeName.length > MAX_ATTRIBUTE_KEY_LENGTH) {
            BSGLogError(@"Span attribute \"%@\" in span %llu (%@) was dropped as the key exceeds the %lu character fixed limit.", attributeName, self.spanId, self.name, MAX_ATTRIBUTE_KEY_LENGTH);
            return;
        }
        [self internalSetAttribute:attributeName withValue:value];
    }
}

- (void)internalSetAttribute:(NSString *)attributeName withValue:(id)value {
    @synchronized (self) {
        if (!self.isMutable) {
            BSGLogError(@"Called setAttribute, but span %llu (%@) is immutable", self.spanId, self.name);
            return;
        }
        if(value == nil) {
            [self.attributes removeObjectForKey:attributeName];
        } else {
            self.attributes[attributeName] = value;
        }
    }
}

- (void)internalSetMultipleAttributes:(NSDictionary *)attributes {
    @synchronized (self) {
        if (!self.isMutable) {
            BSGLogError(@"Called setMultipleAttributes, but span %llu (%@) is immutable", self.spanId, self.name);
            return;
        }
        [self.attributes addEntriesFromDictionary:attributes];
    }
}

- (BOOL)hasAttribute:(NSString *)attributeName withValue:(id)value {
    @synchronized (self) {
        return [self.attributes[attributeName] isEqual:value];
    }
}

- (id)getAttribute:(NSString *)attributeName {
    @synchronized (self) {
        return self.attributes[attributeName];
    }
}

- (void)updateSamplingProbability:(double) value {
    @synchronized (self) {
        if (!self.isMutable) {
            BSGLogError(@"Called updateSamplingProbability, but span %llu (%@) is immutable", self.spanId, self.name);
            return;
        }
        if (self.samplingProbability > value) {
            self.samplingProbability = value;
            self.attributes[@"bugsnag.sampling.p"] = @(value);
        }
    }
}

- (void)setIsMutable:(BOOL)isMutable {
    @synchronized (self) {
        _isMutable = isMutable;
    }
}

- (void)forceMutate:(void (^)())block {
    @synchronized (self) {
        const bool wasMutable = self.isMutable;
        self.isMutable = true;
        block();
        self.isMutable = wasMutable;
    }
}

@end
