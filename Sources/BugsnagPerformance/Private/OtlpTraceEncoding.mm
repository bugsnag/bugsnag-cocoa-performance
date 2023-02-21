//
//  OtlpTraceEncoding.mm
//  BugsnagPerformance
//
//  Created by Nick Dowell on 27/09/2022.
//

#import "OtlpTraceEncoding.h"
#import <CommonCrypto/CommonCrypto.h>
#import "Utils.h"
#import "Gzip.h"

using namespace bugsnag;

static NSString * EncodeSpanId(SpanId const &spanId) {
    return [NSString stringWithFormat:@"%016llx", spanId];
}

static NSString * EncodeTraceId(TraceId const &traceId) {
    return [NSString stringWithFormat:@"%016llx%016llx", traceId.hi, traceId.lo];
}

static NSString * EncodeCFAbsoluteTime(CFAbsoluteTime time) {
    return [NSString stringWithFormat:@"%llu", absoluteTimeToNanoseconds(time)];
}

NSDictionary *
OtlpTraceEncoding::encode(const SpanData &span) noexcept {
    NSMutableDictionary *result = [NSMutableDictionary new];

    // A unique identifier for a trace. All spans from the same trace share
    // the same `trace_id`. The ID is a 16-byte array. An ID with all zeroes
    // is considered invalid.
    //
    // This field is semantically required. Receiver should generate new
    // random trace_id if empty or invalid trace_id was received.
    //
    // This field is required.
    result[@"traceId"] = EncodeTraceId(span.traceId);

    // A unique identifier for a span within a trace, assigned when the span
    // is created. The ID is an 8-byte array. An ID with all zeroes is considered
    // invalid.
    //
    // This field is semantically required. Receiver should generate new
    // random span_id if empty or invalid span_id was received.
    //
    // This field is required.
    result[@"spanId"] = EncodeSpanId(span.spanId);

    // The span ID of this span's parent (if any).
    if (span.parentId != 0) {
        result[@"parentId"] = EncodeSpanId(span.parentId);
    }

    // trace_state conveys information about request position in multiple distributed tracing graphs.
    // It is a trace_state in w3c-trace-context format: https://www.w3.org/TR/trace-context/#tracestate-header
    // See also https://github.com/w3c/distributed-tracing for more details about this field.
    // @"traceState":

    // The `span_id` of this span's parent span. If this is a root span, then this
    // field must be empty. The ID is an 8-byte array.
    // @"parentSpanId":

    // A description of the span's operation.
    //
    // For example, the name can be a qualified method name or a file name
    // and a line number where the operation is called. A best practice is to use
    // the same display name at the same call point in an application.
    // This makes it easier to correlate spans in different traces.
    //
    // This field is semantically required to be set to non-empty string.
    // Empty value is equivalent to an unknown span name.
    //
    // This field is required.
    result[@"name"] = span.name;

    // Distinguishes between spans generated in a particular context. For example,
    // two spans with the same name may be distinguished using `CLIENT` (caller)
    // and `SERVER` (callee) to identify queueing latency associated with the span.
    result[@"kind"] = @(span.kind);

    // start_time_unix_nano is the start time of the span. On the client side, this is the time
    // kept by the local machine where the span execution starts. On the server side, this
    // is the time when the server's application handler starts running.
    // Value is UNIX Epoch time in nanoseconds since 00:00:00 UTC on 1 January 1970.
    //
    // This field is semantically required and it is expected that end_time >= start_time.
    result[@"startTimeUnixNano"] = EncodeCFAbsoluteTime(span.startTime);

    // end_time_unix_nano is the end time of the span. On the client side, this is the time
    // kept by the local machine where the span execution ends. On the server side, this
    // is the time when the server application handler stops running.
    // Value is UNIX Epoch time in nanoseconds since 00:00:00 UTC on 1 January 1970.
    //
    // This field is semantically required and it is expected that end_time >= start_time.
    result[@"endTimeUnixNano"] = EncodeCFAbsoluteTime(span.endTime);

    // attributes is a collection of key/value pairs. Note, global attributes
    // like server name can be set using the resource API.
    // The OpenTelemetry API specification further restricts the allowed value types:
    // https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/common/README.md#attribute
    // Attribute keys MUST be unique (it is not allowed to have more than one
    // attribute with the same key).
    result[@"attributes"] = encode(span.attributes);

    return result;
}

NSDictionary *
OtlpTraceEncoding::encode(const std::vector<std::unique_ptr<SpanData>> &spans, NSDictionary *resourceAttributes) noexcept {
    auto encodedSpans = [NSMutableArray arrayWithCapacity:spans.size()];
    for (const auto &span: spans) {
        [encodedSpans addObject:encode(*span.get())];
    }
    
    // message ExportTraceServiceRequest / message TracesData
    return @{
        
        // An array of ResourceSpans.
        // For data coming from a single resource this array will typically contain
        // one element. Intermediary nodes that receive data from multiple origins
        // typically batch the data before forwarding further and in that case this
        // array will contain multiple elements.
        @"resourceSpans": @[@{
            // A collection of ScopeSpans from a Resource.
            
            // The resource for the spans in this message.
            // If this field is not set then no resource info is known.
            @"resource": @{
                @"attributes": encode(resourceAttributes),
            },
            
            // A list of ScopeSpans that originate from a resource.
            @"scopeSpans": @[@{
                // A collection of Spans produced by an InstrumentationScope.
                
                // The instrumentation scope information for the spans in this message.
                // Semantically when InstrumentationScope isn't set, it is equivalent with
                // an empty instrumentation scope name (unknown).
                // @"scope": ...
                
                // A list of Spans that originate from an instrumentation scope.
                @"spans": encodedSpans,
                
                // This schema_url applies to all spans and span events in the "spans" field.
                // @"schemaUrl": ...
            }],
            
            // This schema_url applies to the data in the "resource" field. It does not apply
            // to the data in the "scope_spans" field which have their own schema_url field.
            // @"schemaUrl": ...
        }]
    };
}

NSArray<NSDictionary *> *
OtlpTraceEncoding::encode(NSDictionary *attributes) noexcept {
    auto result = [NSMutableArray array];
    for (NSString *key in attributes) {
        id value = attributes[key];
        if ([value isKindOfClass:[NSString class]]) {
            [result addObject:@{@"key": key, @"value": @{@"stringValue": value}}];
        }
        if ([value isKindOfClass:[NSNumber class]]) {
            auto typeId = CFGetTypeID((__bridge CFTypeRef)value);
            if (typeId == CFBooleanGetTypeID()) {
                [result addObject:@{@"key": key, @"value": @{@"boolValue": value}}];
            }
            else if (typeId == CFNumberGetTypeID()) {
                auto type = CFNumberGetType((__bridge CFNumberRef)value);
                switch (type) {
                    case kCFNumberSInt8Type:
                    case kCFNumberSInt16Type:
                    case kCFNumberSInt32Type:
                    case kCFNumberCharType:
                    case kCFNumberShortType:
                    case kCFNumberIntType:
                        [result addObject:@{@"key": key, @"value": @{@"intValue": value}}];
                        break;
                        
                    case kCFNumberLongType:
                    case kCFNumberCFIndexType:
                    case kCFNumberNSIntegerType:
                    case kCFNumberSInt64Type:
                    case kCFNumberLongLongType:
                        // "JSON value will be a decimal string. Either numbers or strings are accepted."
                        // https://developers.google.com/protocol-buffers/docs/proto3#json
                        [result addObject:@{@"key": key, @"value": @{@"intValue": [value stringValue]}}];
                        break;
                        
                    case kCFNumberFloat32Type:
                    case kCFNumberFloat64Type:
                    case kCFNumberFloatType:
                    case kCFNumberDoubleType:
                    case kCFNumberCGFloatType:
                        [result addObject:@{@"key": key, @"value": @{@"doubleValue": value}}];
                        break;
                        
                    default: break;
                }
            }
        }
    }
    return result;
}

static dispatch_time_t getLatestTimestamp(const std::vector<std::unique_ptr<SpanData>> &spans) {
    CFAbsoluteTime endTime = 0;
    for (auto &span: spans) {
        if (span->endTime > endTime) {
            endTime = span->endTime;
        }
    }
    return absoluteTimeToNanoseconds(endTime);
}

static NSString *integrityDigestForData(NSData *payload) {
    unsigned char md[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(payload.bytes, (CC_LONG)payload.length, md);
    return [NSString stringWithFormat:@"sha1 %02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                   md[0], md[1], md[2], md[3], md[4],
                   md[5], md[6], md[7], md[8], md[9],
                   md[10], md[11], md[12], md[13], md[14],
                   md[15], md[16], md[17], md[18], md[19]];
}

static NSString *pValueHistogramForSpans(const std::vector<std::unique_ptr<SpanData>> &spans) {
    // Calculate P value histogram the hard way because ObjC doesn't have such conveniences.

    NSMutableArray<NSNumber *> *ordered = [[NSMutableArray alloc] initWithCapacity:spans.size()];
    NSMutableDictionary<NSNumber *, NSNumber *> *counts = [NSMutableDictionary new];

    for (const std::unique_ptr<SpanData> &span: spans) {
        auto probability = @(span->samplingProbability);
        auto count = counts[probability];
        if (count == nil) {
            [ordered addObject:probability];
            counts[probability] = @(1);
        } else {
            counts[probability] = @(count.unsignedIntValue + 1);
        }
    }

    [ordered sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        auto flt1 = [obj1 doubleValue];
        auto flt2 = [obj2 doubleValue];
        if (flt1 == flt2) {
            return NSOrderedSame;
        }
        if (flt1 < flt2) {
            return NSOrderedAscending;
        }
        return NSOrderedDescending;
    }];

    NSMutableString *str = [[NSMutableString alloc] init];
    for (NSUInteger i = 0; i < ordered.count; i++) {
        if (i > 0 && i <= ordered.count-1) {
            [str appendString:@";"];
        }
        NSNumber *probability = ordered[i];
        [str appendFormat:@"%@:%@", probability, counts[probability]];
    }
    return str;
}

std::unique_ptr<OtlpPackage> OtlpTraceEncoding::buildUploadPackage(const std::vector<std::unique_ptr<SpanData>> &spans, NSDictionary *resourceAttributes) noexcept {
    // Anything smaller won't compress
    static const int MIN_SIZE_FOR_GZIP = 128;

    auto encodedSpans = encode(spans, resourceAttributes);

    NSError *error = nil;
    auto payload = [NSJSONSerialization dataWithJSONObject:encodedSpans options:0 error:&error];
    if (!payload) {
        NSCAssert(NO, @"%@", error);
        return nullptr;
    }

    auto headers = @{
        @"Content-Type": @"application/json",
        @"Bugsnag-Integrity": integrityDigestForData(payload),
        @"Bugsnag-Span-Sampling": pValueHistogramForSpans(spans),
    };

    if (payload.length > MIN_SIZE_FOR_GZIP) {
        payload = [Gzip gzipped:(NSData * _Nonnull)payload error:&error];
        if (payload == nil || error != nil) {
            BSGLogError(@"error compressing payload: %@", error);
            return nullptr;
        }
        NSMutableDictionary *newHeaders = [headers mutableCopy];
        newHeaders[@"Content-Encoding"] = @"gzip";
        headers = newHeaders;
    }

    return std::make_unique<OtlpPackage>(getLatestTimestamp(spans), payload, headers);
}

std::unique_ptr<OtlpPackage> OtlpTraceEncoding::buildPValueRequestPackage() noexcept {
    auto emptyPayload = [@"{\"resourceSpans\": []}" dataUsingEncoding:NSUTF8StringEncoding];
    return std::make_unique<OtlpPackage>(0, emptyPayload, @{
        @"Content-Type": @"application/json",
        @"Bugsnag-Integrity": integrityDigestForData(emptyPayload),
        @"Bugsnag-Span-Sampling": @"1:0",
    });
}
