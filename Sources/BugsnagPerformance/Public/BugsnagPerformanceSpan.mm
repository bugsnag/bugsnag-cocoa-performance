//
//  BugsnagPerformanceSpan.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "../Private/BugsnagPerformanceSpan+Private.h"
#import "../Private/Utils.h"

using namespace bugsnag;

static const uint64_t MONOTONIC_CLOCK_INVALID = 0;

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
                  firstClass:(BSGFirstClass) firstClass
                 onSpanClosed:(OnSpanClosed) onSpanClosed {
    if ((self = [super initWithTraceId:traceId spanId:spanId])) {
        _startClock = currentMonotonicClockNsecIfUnset(startAbsTime);
        _name = name;
        _parentId = parentId;
        _startAbsTime = currentTimeIfUnset(startAbsTime);
        _startClock = currentMonotonicClockNsecIfUnset(startAbsTime);
        _firstClass = firstClass;
        _onSpanDestroyAction = OnSpanDestroyAbort;
        _onSpanClosed = onSpanClosed;
        _kind = SPAN_KIND_INTERNAL;
        _samplingProbability = 1;
        _state = SpanStateOpen;
        _attributes = [[NSMutableDictionary alloc] init];
        if (firstClass != BSGFirstClassUnset) {
            _attributes[@"bugsnag.span.first_class"] = @(firstClass == BSGFirstClassYes);
        }
        _attributes[@"bugsnag.sampling.p"] = @(1.0);
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
    [self callOnSpanClosed];
}

- (void)abortUnconditionally {
    bool wasOpen = false;
    @synchronized (self) {
        BSGLogDebug(@"Span.abortUnconditionally: %@: Was open: %d", self.name, self.state == SpanStateOpen);
        wasOpen = self.state == SpanStateOpen;
        self.state = SpanStateAborted;
    }
    if (wasOpen) {
        [self callOnSpanClosed];
    }
}

- (void)end {
    [self endWithAbsoluteTime:CFABSOLUTETIME_INVALID];
}

- (void)endWithEndTime:(NSDate *)endTime {
    [self endWithAbsoluteTime:(dateToAbsoluteTime(endTime))];
}

- (void)endWithAbsoluteTime:(CFAbsoluteTime)endTime {
    @synchronized (self) {
        BSGLogDebug(@"Span.endWithAbsoluteTime(%f): %@: Was open: %d", endTime, self.name, self.state == SpanStateOpen);
        if (self.state != SpanStateOpen) {
            // The span has already been closed or aborted.
            return;
        }

        // If our start and end times were both "unset", then it's on us to counter any
        // clock skew using the monotonic clock.
        if (isMonotonicClockValid(self.startClock)) {
            auto endClock = currentMonotonicClockNsecIfUnset(endTime);
            if (isMonotonicClockValid(endClock)) {
                // Calculate using signed int so that an end time < start time doesn't overflow.
                endTime = self.startAbsTime + ((double)((int64_t)endClock - (int64_t)self.startClock)) / NSEC_PER_SEC;
            }
        }

        self.endAbsTime = currentTimeIfUnset(endTime);
        self.state = SpanStateEnded;
    }
    [self callOnSpanClosed];
}

- (void)callOnSpanClosed {
    auto onSpanClosed = self.onSpanClosed;
    if(onSpanClosed != nil) {
        onSpanClosed(self);
    }
}

- (void)endOnDestroy {
    self.onSpanDestroyAction = OnSpanDestroyEnd;
}

- (NSDate *)startTime {
    return [NSDate dateWithTimeIntervalSinceReferenceDate:self.startAbsTime];
}

- (NSDate *)endTime {
    return [NSDate dateWithTimeIntervalSinceReferenceDate:self.endAbsTime];
}

- (void)updateStartTime:(NSDate *)startTime {
    self.startAbsTime = dateToAbsoluteTime(startTime);
    self.startClock = currentMonotonicClockNsecIfUnset(self.startAbsTime);
}

- (void)updateName:(NSString *)name {
    self.name = name;
}

- (BOOL)isValid {
    return self.state == SpanStateOpen;
}

- (void)setAttribute:(NSString *)attributeName withValue:(id)value {
    @synchronized (self) {
        if(value == nil) {
            [self.attributes removeObjectForKey:attributeName];
        } else {
            self.attributes[attributeName] = value;
        }
    }
}

- (void)setMultipleAttributes:(NSDictionary *)attributes {
    @synchronized (self) {
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
        if (self.samplingProbability > value) {
            self.samplingProbability = value;
            self.attributes[@"bugsnag.sampling.p"] = @(value);
        }
    }
}

@end
