//
//  BugsnagPerformanceSpan.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "../Private/BugsnagPerformanceSpan+Private.h"
#import "../Private/Utils.h"

using namespace bugsnag;

@implementation BugsnagPerformanceSpan {
    std::unique_ptr<Span> _span;
}

- (instancetype)initWithSpan:(std::unique_ptr<Span>)span {
    if ((self = [super init])) {
        _span = std::move(span);
    }
    return self;
}

- (void)dealloc {
    if (self.isValid && self.onDumped) {
        self.onDumped(self);
    }
}

// We want direct ivar access to avoid accessors copying unique_ptrs
#pragma clang diagnostic ignored "-Wdirect-ivar-access"

- (void)abort {
    _span->abort();
}

- (void)end {
    _span->end(CFABSOLUTETIME_INVALID);
}

- (void)endWithEndTime:(NSDate *)endTime {
    _span->end(dateToAbsoluteTime(endTime));
}

- (void)endWithAbsoluteTime:(CFAbsoluteTime)endTime {
    _span->end(endTime);
}

- (TraceId)traceId {
    return _span->traceId();
}

- (SpanId)spanId {
    return _span->spanId();
}

- (SpanId)parentId {
    return _span->parentId();
}

- (NSString *)name {
    return _span->name();
}

- (NSDate *)startTime {
    return [NSDate dateWithTimeIntervalSinceReferenceDate:_span->startTime()];
}

- (NSDate *)endTime {
    return [NSDate dateWithTimeIntervalSinceReferenceDate:_span->endTime()];
}

- (void)updateStartTime:(NSDate *)startTime {
    _span->updateStartTime(dateToAbsoluteTime(startTime));
}

- (void)updateName:(NSString *)name {
    _span->updateName(name);
}

- (BOOL)isValid {
    return !_span->isEnded();
}

- (void)addAttribute:(NSString *)attributeName withValue:(id)value {
    _span->addAttribute(attributeName, value);
}

- (void)addAttributes:(NSDictionary *)attributes {
    _span->addAttributes(attributes);
}

- (BOOL)hasAttribute:(NSString *)attributeName withValue:(id)value {
    return _span->hasAttribute(attributeName, value);
}

- (id)getAttribute:(NSString *)attributeName {
    return _span->getAttribute(attributeName);
}

@end
