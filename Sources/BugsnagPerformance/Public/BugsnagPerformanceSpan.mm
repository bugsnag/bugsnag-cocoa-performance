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

- (instancetype) initWithName:(NSString *)name
                      traceId:(TraceId)traceId
                       spanId:(SpanId)spanId
                     parentId:(SpanId)parentId
                    startTime:(CFAbsoluteTime)startTime
                   firstClass:(BSGFirstClass)firstClass
                        onEnd:(OnSpanEnd)onEnd {
    if ((self = [super initWithTraceId:traceId spanId:spanId])) {
        _name = name;
        _parentId = parentId;
        _startTime = startTime;
        _firstClass = firstClass;
        _onEnd = onEnd;
        _startClock = currentMonotonicClockNsecIfUnset(startTime);
        _spanDestroyAction = AbortOnSpanDestroy;
        _isEnded = false;
        _isValid = true;
        _samplingProbability = 1.0;
        _attributes = [NSMutableDictionary dictionary];
        _kind = SPAN_KIND_INTERNAL;

        if (firstClass != BSGFirstClassUnset) {
            self.attributes[@"bugsnag.span.first_class"] = @(firstClass == BSGFirstClassYes);
        }
        self.attributes[@"bugsnag.sampling.p"] = @(_samplingProbability);
    }
    return self;
}

- (void)dealloc {
    if (self.isValid && self.onDumped) {
        self.onDumped(self);
    }

    switch(self.spanDestroyAction) {
        case AbortOnSpanDestroy:
            BSGLogDebug(@"Span::~Span(): for span %@. Action = Abort", data_->name);
            [self abortIfOpen];
            break;
        case EndOnSpanDestroy:
            BSGLogDebug(@"Span::~Span(): for span %@. Action = End", data_->name);
            [self endWithAbsoluteTime:CFAbsoluteTimeGetCurrent()];
            break;
    }
}

#pragma clang diagnostic ignored "-Wdirect-ivar-access"
- (void)updateSamplingProbability:(double)newSamplingProbability {
    double samplingProbability = _samplingProbability;
    if (samplingProbability > newSamplingProbability) {
        @synchronized (self) {
            _samplingProbability = newSamplingProbability;
            self.attributes[@"bugsnag.sampling.p"] = @(newSamplingProbability);
        }
    }
}

#pragma clang diagnostic ignored "-Wdirect-ivar-access"
- (void)abortIfOpen {
    BSGLogDebug(@"Span::abortIfOpen(): isEnded_ = %s", _isEnded ? "true" : "false");
    @synchronized (self) {
        if (!_isEnded) {
            _isEnded = true;
            _isValid = false;
        }
    }
}

#pragma clang diagnostic ignored "-Wdirect-ivar-access"
- (void)abortUnconditionally {
    BSGLogDebug(@"Span::abortUnconditionally()");
    _isEnded = true;
    _isValid = false;
}

- (void)end {
    [self endWithAbsoluteTime:CFABSOLUTETIME_INVALID];
}

- (void)endWithEndTime:(NSDate *)endTime {
    [self endWithAbsoluteTime:dateToAbsoluteTime(endTime)];
}

#pragma clang diagnostic ignored "-Wdirect-ivar-access"
- (void)endWithAbsoluteTime:(CFAbsoluteTime)endTime {
    BSGLogDebug(@"Span::end(%f)", time);
    @synchronized (self) {
        if (_isEnded) {
            return;
        }
        _isEnded = true;
    }

    // If our start and end times were both "unset", then it's on us to counter any
    // clock skew using the monotonic clock.
    uint64_t startClock = _startClock;
    if (isMonotonicClockValid(startClock)) {
        uint64_t endClock = currentMonotonicClockNsecIfUnset(endTime);
        if (isMonotonicClockValid(endClock)) {
            // Calculate using signed int so that an end time < start time doesn't overflow.
            endTime = _startTime + ((double)((int64_t)endClock - (int64_t)startClock)) / NSEC_PER_SEC;
        }
    }

    self.endTime = currentTimeIfUnset(endTime);
    self.onEnd(self);
}

#pragma clang diagnostic ignored "-Wdirect-ivar-access"
- (NSDate *)startNSDate {
    return [NSDate dateWithTimeIntervalSinceReferenceDate:_startTime];
}

- (void)setStartNSDate:(NSDate *)date {
    self.startTime = date.timeIntervalSinceReferenceDate;
}

#pragma clang diagnostic ignored "-Wdirect-ivar-access"
- (NSDate *)endNSDate {
    return [NSDate dateWithTimeIntervalSinceReferenceDate:_endTime];
}

#pragma clang diagnostic ignored "-Wdirect-ivar-access"
- (BOOL)isValid {
    return !_isEnded;
}

- (void)addAttribute:(NSString *)attributeName withValue:(id)value {
    @synchronized (self) {
        self.attributes[attributeName] = value;
    }
}

- (void)addAttributes:(NSDictionary *)attributes {
    @synchronized (self) {
        [self.attributes addEntriesFromDictionary:attributes];
    }
}

- (BOOL)hasAttribute:(NSString *)attributeName withValue:(id)value {
    @synchronized (self) {
        for (id key in self.attributes) {
            if ([key isEqualToString:attributeName]) {
                return [self.attributes[key] isEqual:value];
            }
        }
    }
    return FALSE;
}

- (id)getAttribute:(NSString *)attributeName {
    return self.attributes[attributeName];
}

@end
