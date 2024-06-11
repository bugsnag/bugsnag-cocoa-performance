//
//  BugsnagPerformanceSpan.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 23/09/2022.
//

#import "../Private/BugsnagPerformanceSpan+Private.h"
#import "../Private/Utils.h"

using namespace bugsnag;

@implementation BugsnagPerformanceSpan

- (instancetype)initWithSpan:(std::shared_ptr<Span>)span {
    if ((self = [super init])) {
        self.span = span;
    }
    return self;
}

- (void)dealloc {
    if (self.isValid && self.onDumped) {
        self.onDumped(self);
    }
}

- (void)abortIfOpen {
    self.span->abortIfOpen();
}

- (void)abortUnconditionally {
    self.span->abortUnconditionally();
}

- (void)end {
    self.span->end(CFABSOLUTETIME_INVALID);
}

- (void)endWithEndTime:(NSDate *)endTime {
    self.span->end(dateToAbsoluteTime(endTime));
}

- (void)endWithAbsoluteTime:(CFAbsoluteTime)endTime {
    self.span->end(endTime);
}

- (void)endOnDestroy {
    self.span->spanDestroyAction = EndOnSpanDestroy;
}

- (TraceId)traceId {
    return self.span->traceId();
}

- (SpanId)spanId {
    return self.span->spanId();
}

- (SpanId)parentId {
    return self.span->parentId();
}

- (NSString *)name {
    return self.span->name();
}

- (NSDate *)startTime {
    return [NSDate dateWithTimeIntervalSinceReferenceDate:self.span->startTime()];
}

- (NSDate *)endTime {
    return [NSDate dateWithTimeIntervalSinceReferenceDate:self.span->endTime()];
}

- (void)updateStartTime:(NSDate *)startTime {
    self.span->updateStartTime(dateToAbsoluteTime(startTime));
}

- (void)updateName:(NSString *)name {
    self.span->updateName(name);
}

- (BOOL)isValid {
    return !self.span->isEnded();
}

- (void)addAttribute:(NSString *)attributeName withValue:(id)value {
    self.span->addAttribute(attributeName, value);
}

- (void)addAttributes:(NSDictionary *)attributes {
    self.span->addAttributes(attributes);
}

- (BOOL)hasAttribute:(NSString *)attributeName withValue:(id)value {
    return self.span->hasAttribute(attributeName, value);
}

- (id)getAttribute:(NSString *)attributeName {
    return self.span->getAttribute(attributeName);
}

@end
