//
//  PlainSpanFactoryImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 15/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "PlainSpanFactoryImpl.h"

using namespace bugsnag;

BugsnagPerformanceSpan *
PlainSpanFactoryImpl::startSpan(NSString *name,
                                const SpanOptions &options,
                                BSGTriState defaultFirstClass,
                                NSDictionary *attributes,
                                NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept {
    return startSpan(name,
                     options,
                     defaultFirstClass,
                     SPAN_KIND_INTERNAL,
                     attributes,
                     conditionsToEndOnClose);
}

BugsnagPerformanceSpan *
PlainSpanFactoryImpl::startSpan(NSString *name,
                                const SpanOptions &options,
                                BSGTriState defaultFirstClass,
                                SpanKind kind,
                                NSDictionary *attributes,
                                NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept {
    auto parentSpan = options.parentContext;
    if (parentSpan == nil) {
        parentSpan = spanStackingHandler_->currentSpan();
    }

    TraceId traceId = { .hi = parentSpan.traceIdHi, .lo = parentSpan.traceIdLo };
    if (traceId.value == 0) {
        traceId = IdGenerator::generateTraceId();
    }
    BSGTriState firstClass = options.firstClass;
    if (firstClass == BSGTriStateUnset) {
        firstClass = defaultFirstClass;
    }
    auto spanId = IdGenerator::generateSpanId();
    
    __block auto blockThis = this;
    auto onSpanEndSet = ^(BugsnagPerformanceSpan * _Nonnull span) {
        if (blockThis->callbacks_.onSpanEndSet != nil) {
            blockThis->callbacks_.onSpanEndSet(span);
        }
    };
    auto onSpanClosed = ^(BugsnagPerformanceSpan * _Nonnull span) {
        if (blockThis->callbacks_.onSpanClosed != nil) {
            blockThis->callbacks_.onSpanClosed(span);
        }
    };
    auto onSpanBlocked = ^BugsnagPerformanceSpanCondition * _Nullable(BugsnagPerformanceSpan * _Nonnull span, NSTimeInterval timeout) {
        if (blockThis->callbacks_.onSpanBlocked != nil) {
            return blockThis->callbacks_.onSpanBlocked(span, timeout);
        }
        return nil;
    };
    auto onSpanCancelled = ^(BugsnagPerformanceSpan * _Nonnull span) {
        if (blockThis->callbacks_.onSpanCancelled != nil) {
            blockThis->callbacks_.onSpanCancelled(span);
        }
    };

    BugsnagPerformanceSpan *span = [[BugsnagPerformanceSpan alloc] initWithName:name
                                                                        traceId:traceId
                                                                         spanId:spanId
                                                                       parentId:parentSpan.spanId
                                                                      startTime:options.startTime
                                                                     firstClass:firstClass
                                                            samplingProbability:sampler_->getProbability()
                                                            attributeCountLimit:attributeCountLimit_
                                                                 metricsOptions:options.metricsOptions
                                                         conditionsToEndOnClose:conditionsToEndOnClose
                                                                   onSpanEndSet:onSpanEndSet
                                                                   onSpanClosed:onSpanClosed
                                                                  onSpanBlocked:onSpanBlocked
                                                                onSpanCancelled:onSpanCancelled];
    NSMutableDictionary *initialAttributes = spanAttributesProvider_->initialAttributes();
    [initialAttributes addEntriesFromDictionary:attributes];
    [span internalSetMultipleAttributes:initialAttributes];
    span.kind = kind;
    callbacks_.onSpanStarted(span, options);
    return span;
}
