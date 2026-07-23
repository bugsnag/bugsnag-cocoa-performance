//
//  SpanAttributesProvider.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 21/04/2023.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "SpanAttributesProvider.h"
#import <Foundation/Foundation.h>
#import "Utils.h"
#import <algorithm>
#if TARGET_OS_IOS
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#endif

using namespace bugsnag;

static NSDictionary *accessTechnologyMappingDictionary();

// https://stackoverflow.com/questions/58426438/what-is-key-in-cttelephonynetworkinfo-servicesubscribercellularproviders-and-c
static NSString * const networkSubtypeKey = @"0000000100000001";
static NSString * const connectionTypeCell = @"cell";
static NSString * const BSGSpanCategoryAppSession = @"app_session";
static const NSUInteger graphQLMaximumBodySize = 64 * 1024;
static const NSUInteger graphQLMaximumOperationNameLength = 256;

static NSString *sanitizeSessionTypeIdentifier(NSString *sessionType) {
    NSCharacterSet *separatorCharacterSet = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    NSRange sepRange = [sessionType rangeOfCharacterFromSet:separatorCharacterSet];
    if (sepRange.location == NSNotFound && sessionType.length > 0) {
        return sessionType;
    }

    NSMutableString *sanitized = [NSMutableString string];
    for (NSString *component in [sessionType componentsSeparatedByCharactersInSet:separatorCharacterSet]) {
        if (component.length == 0) {
            continue;
        }

        NSString *lowercasedComponent = component.lowercaseString;
        NSString *capitalizedComponent = [lowercasedComponent stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                                                       withString:[[lowercasedComponent substringToIndex:1] uppercaseString]];
        [sanitized appendString:capitalizedComponent];
    }

    return sanitized.length > 0 ? sanitized : @"Session";
}

SpanAttributesProvider::SpanAttributesProvider() noexcept {};

static NSString *getHTTPFlavour(NSURLSessionTaskMetrics *metrics) {
    for (NSURLSessionTaskTransactionMetrics *transactionMetrics in metrics.transactionMetrics) {
        NSString *protocolName = transactionMetrics.networkProtocolName;
        if ([protocolName isEqualToString:@"http/1.1"]) {
            return @"1.1";
        }
        if ([protocolName isEqualToString:@"h2"]) {
            return @"2.0";
        }
        if ([protocolName isEqualToString:@"h3"]) {
            return @"3.0";
        }
        if ([protocolName hasPrefix:@"spdy/"]) {
            return @"SPDY";
        }
    }
    return nil;
}

static NSString *getConnectionType(NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) {
    if (task.error.code == NSURLErrorNotConnectedToInternet) {
        return @"unavailable";
    }
    if (@available(macos 10.15 , ios 13.0 , watchos 6.0 , tvos 13.0, *)) {
        auto transactionMetrics = metrics.transactionMetrics;
        if (transactionMetrics.count > 0 && transactionMetrics[0].cellular) {
            return connectionTypeCell;
        }
    }
    return @"wifi";
}

static NSDictionary *accessTechnologyMappingDictionary() {
    static NSMutableDictionary *accessTechnologyMapping;
    static dispatch_once_t onceT;
    dispatch_once(&onceT, ^(){
        accessTechnologyMapping = [@{
#if TARGET_OS_IOS
            CTRadioAccessTechnologyGPRS: @"gprs",
            CTRadioAccessTechnologyEdge: @"edge",
            CTRadioAccessTechnologyWCDMA: @"wcdma",
            CTRadioAccessTechnologyHSDPA: @"hsdpa",
            CTRadioAccessTechnologyHSUPA: @"hsupa",
            CTRadioAccessTechnologyCDMA1x: @"cdma",
            CTRadioAccessTechnologyCDMAEVDORev0: @"evdo_0",
            CTRadioAccessTechnologyCDMAEVDORevA: @"evdo_a",
            CTRadioAccessTechnologyCDMAEVDORevB: @"evdo_b",
            CTRadioAccessTechnologyeHRPD: @"ehrpd",
            CTRadioAccessTechnologyLTE: @"lte",
#endif
        } mutableCopy];
#if TARGET_OS_IOS
        if (@available(iOS 14.1, *)) {
            accessTechnologyMapping[CTRadioAccessTechnologyNRNSA] = @"nrnsa";
            accessTechnologyMapping[CTRadioAccessTechnologyNR] = @"nr";
        }
#endif
    });
    return accessTechnologyMapping;
}

static NSString *getConnectionSubtype(NSString *networkType) {
    if ([networkType isEqual:connectionTypeCell]) {
#if TARGET_OS_IOS
        NSString *accessTechnology = [[CTTelephonyNetworkInfo new].serviceCurrentRadioAccessTechnology objectForKey:networkSubtypeKey];
        if (accessTechnology) {
            return accessTechnologyMappingDictionary()[accessTechnology];
        }
#endif
    }
    return nil;
}

static void addNonZero(NSMutableDictionary *dict, NSString *key, NSNumber *value) {
    if (value.floatValue != 0) {
        dict[key] = value;
    }
}

static BOOL isGraphQLNameCharacter(unichar character, BOOL firstCharacter) {
    BOOL isLetter = (character >= 'A' && character <= 'Z') || (character >= 'a' && character <= 'z');
    return isLetter || character == '_' || (!firstCharacter && character >= '0' && character <= '9');
}

static NSString *validatedGraphQLOperationName(id value) {
    if (![value isKindOfClass:NSString.class]) return nil;
    NSString *name = value;
    if (name.length == 0 || name.length > graphQLMaximumOperationNameLength) return nil;
    for (NSUInteger index = 0; index < name.length; index++) {
        if (!isGraphQLNameCharacter([name characterAtIndex:index], index == 0)) return nil;
    }
    return name;
}

static NSUInteger skipGraphQLIgnoredCharacters(NSString *document, NSUInteger index) {
    while (index < document.length) {
        unichar character = [document characterAtIndex:index];
        if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:character] || character == ',' || character == 0xFEFF) {
            index++;
        } else if (character == '#') {
            while (index < document.length && [document characterAtIndex:index] != '\n' && [document characterAtIndex:index] != '\r') index++;
        } else {
            break;
        }
    }
    return index;
}

static NSString *readGraphQLName(NSString *document, NSUInteger *index) {
    NSUInteger start = *index;
    if (start >= document.length || !isGraphQLNameCharacter([document characterAtIndex:start], YES)) return nil;
    (*index)++;
    while (*index < document.length && isGraphQLNameCharacter([document characterAtIndex:*index], NO)) (*index)++;
    return [document substringWithRange:NSMakeRange(start, *index - start)];
}

static NSUInteger skipGraphQLString(NSString *document, NSUInteger index) {
    BOOL blockString = index + 2 < document.length && [document characterAtIndex:index + 1] == '"' && [document characterAtIndex:index + 2] == '"';
    index += blockString ? 3 : 1;
    while (index < document.length) {
        if (blockString && index + 2 < document.length && [document characterAtIndex:index] == '"' &&
            [document characterAtIndex:index + 1] == '"' && [document characterAtIndex:index + 2] == '"') return index + 3;
        unichar character = [document characterAtIndex:index++];
        if (!blockString && character == '\\' && index < document.length) index++;
        else if (!blockString && character == '"') return index;
    }
    return index;
}

static void extractGraphQLOperation(NSString *document,
                                    NSString *requestedOperationName,
                                    NSString **operationType,
                                    NSString **operationName) {
    // The ED requires query as the fallback when the document does not expose an
    // explicit query, mutation, or subscription keyword.
    *operationType = @"query";
    *operationName = requestedOperationName;
    if (![document isKindOfClass:NSString.class] || document.length == 0) return;
    NSUInteger index = 0;
    NSUInteger selectionDepth = 0;
    BOOL atDefinitionStart = YES;
    while (index < document.length) {
        index = skipGraphQLIgnoredCharacters(document, index);
        if (index >= document.length) break;
        unichar character = [document characterAtIndex:index];
        if (character == '"') {
            index = skipGraphQLString(document, index);
            atDefinitionStart = NO;
        } else if (character == '{') {
            if (selectionDepth == 0 && atDefinitionStart && requestedOperationName == nil) {
                *operationType = @"query";
                return;
            }
            selectionDepth++;
            atDefinitionStart = NO;
            index++;
        } else if (character == '}') {
            if (selectionDepth > 0 && --selectionDepth == 0) atDefinitionStart = YES;
            index++;
        } else if (selectionDepth == 0 && atDefinitionStart && isGraphQLNameCharacter(character, YES)) {
            NSString *token = readGraphQLName(document, &index);
            BOOL isOperation = [token isEqualToString:@"query"] || [token isEqualToString:@"mutation"] || [token isEqualToString:@"subscription"];
            if (isOperation) {
                index = skipGraphQLIgnoredCharacters(document, index);
                NSString *declaredName = readGraphQLName(document, &index);
                if (requestedOperationName == nil || [declaredName isEqualToString:requestedOperationName]) {
                    *operationType = token;
                    if (requestedOperationName == nil) *operationName = validatedGraphQLOperationName(declaredName);
                    return;
                }
            }
            atDefinitionStart = NO;
        } else {
            index++;
        }
    }
}

static BOOL dataContainsGraphQLJSONKey(NSData *data) {
    static NSArray<NSData *> *operationKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        operationKeys = @[
            (NSData * _Nonnull)[@"\"query\"" dataUsingEncoding:NSUTF8StringEncoding],
            (NSData * _Nonnull)[@"\"mutation\"" dataUsingEncoding:NSUTF8StringEncoding],
            (NSData * _Nonnull)[@"\"subscription\"" dataUsingEncoding:NSUTF8StringEncoding],
        ];
    });
    for (NSData *key in operationKeys) {
        if ([data rangeOfData:key options:0 range:NSMakeRange(0, data.length)].location != NSNotFound) return YES;
    }
    return NO;
}

static BOOL isGraphQLEndpointPath(NSString *path) {
    for (NSString *component in path.pathComponents) {
        if ([component caseInsensitiveCompare:@"graphql"] == NSOrderedSame) return YES;
    }
    return NO;
}

static BOOL addGraphQLDocumentAttributes(NSMutableDictionary *attributes,
                                         NSString *document,
                                         NSString *requestedName,
                                         NSString *hintedType,
                                         NSURL *url) {
    if (url == nil) return NO;
    // Avoid false positives: endpoint/content-type hints alone are not enough
    // to construct GraphQL semantics. We only classify when a readable GraphQL
    // document is available. This keeps ordinary HTTP traffic in the existing
    // network category, as required by the ED.
    if (![document isKindOfClass:NSString.class] ||
        document.length == 0 ||
        [document rangeOfString:@"{"].location == NSNotFound) {
        return NO;
    }
    NSString *endpoint = url.path.length > 0 ? url.path : @"/";
    NSString *operationType = nil;
    NSString *operationName = nil;
    extractGraphQLOperation(document,
                            validatedGraphQLOperationName(requestedName),
                            &operationType,
                            &operationName);
    if (hintedType.length > 0 && [operationType isEqualToString:@"query"] &&
        [document rangeOfString:@"mutation" options:NSCaseInsensitiveSearch].location == NSNotFound &&
        [document rangeOfString:@"subscription" options:NSCaseInsensitiveSearch].location == NSNotFound) {
        operationType = hintedType;
    }

    attributes[@"bugsnag.span.category"] = @"graphql";
    attributes[@"bugsnag.span.first_class"] = @YES;
    // These two values are temporary SDK metadata used to construct the internal
    // span name. Callers remove them before attaching attributes to the span.
    attributes[@"graphql.operation.type"] = operationType;
    if (operationName != nil) attributes[@"graphql.operation.name"] = operationName;
    attributes[@"display_name"] = operationName == nil
        ? [NSString stringWithFormat:@"%@ %@", operationType, endpoint]
        : [NSString stringWithFormat:@"%@ %@ (%@)", operationType, endpoint, operationName];
    BSGLogDebug(@"GraphQL operation extracted: endpoint=%@ operationType=%@ operationName=%@ displayName=%@",
                endpoint,
                operationType,
                operationName ?: @"<anonymous>",
                attributes[@"display_name"]);
    BSGLogDebug(@"GraphQL request detected: endpoint=%@ operationType=%@ operationName=%@ attributes=%@",
                endpoint,
                operationType,
                operationName ?: @"<anonymous>",
                attributes);
    return YES;
}

static BOOL addGraphQLPayloadAttributes(NSMutableDictionary *attributes, NSDictionary *payload, NSURL *url) {
    NSArray<NSString *> *keys = @[@"query", @"mutation", @"subscription"];
    for (NSString *key in keys) {
        NSString *document = [payload[key] isKindOfClass:NSString.class] ? payload[key] : nil;
        if (document.length > 0 && [document rangeOfString:@"{"].location != NSNotFound) {
            NSString *hintedType = [key isEqualToString:@"query"] ? nil : key;
            return addGraphQLDocumentAttributes(attributes,
                                                document,
                                                payload[@"operationName"],
                                                hintedType,
                                                url);
        }
    }
    return NO;
}

static uint64_t CFAbsoluteTimeToUTCNanos(CFAbsoluteTime time) {
    return (uint64_t)((time + kCFAbsoluteTimeIntervalSince1970) * NSEC_PER_SEC);
}

NSMutableDictionary *
SpanAttributesProvider::initialNetworkSpanAttributes() noexcept {
    BSGLogTrace(@"SpanAttributesProvider::initialNetworkSpanAttributes");
    auto attributes = [NSMutableDictionary new];
    attributes[@"bugsnag.span.category"] = @"network";
    attributes[@"http.url"] = @"unknown";
    return attributes;
}

NSMutableDictionary *
SpanAttributesProvider::networkSpanAttributes(NSURL *url,
                                              NSURLSessionTask *task,
                                              NSURLSessionTaskMetrics *metrics,
                                              NSError *encounteredError) noexcept {
    BSGLogTrace(@"SpanAttributesProvider::networkSpanAttributes(%@, task, metrics, error)", url);
    auto httpResponse = BSGDynamicCast<NSHTTPURLResponse>(task.response);
    auto attributes = [NSMutableDictionary new];
    attributes[@"bugsnag.span.category"] = @"network";
    if (url != nil) {
        attributes[@"http.url"] = url.absoluteString;
    }
    if (encounteredError != nil) {
        BSGLogTrace(@"SpanAttributesProvider::networkSpanAttributes: Caller encountered error \"%@\". Adding instrumentation_message attribute", encounteredError.description);
        [attributes addEntriesFromDictionary:internalErrorAttributes(encounteredError)];
    }
    attributes[@"http.flavor"] = getHTTPFlavour(metrics);
    attributes[@"http.method"] = getTaskRequest(task, nil).HTTPMethod;
    attributes[@"http.status_code"] = httpResponse ? @(httpResponse.statusCode) : @0;
    attributes[@"net.host.connection.type"] = getConnectionType(task, metrics);
    attributes[@"net.host.connection.subtype"] = getConnectionSubtype(attributes[@"net.host.connection.type"]);
    addNonZero(attributes, @"http.request_content_length", @(task.countOfBytesSent));
    addNonZero(attributes, @"http.response_content_length", @(task.countOfBytesReceived));
    return attributes;
}

NSMutableDictionary *
SpanAttributesProvider::graphQLAttributes(NSURLRequest *request, NSURL *reportedURL) noexcept {
    auto attributes = [NSMutableDictionary new];
    @try {
        NSString *method = request.HTTPMethod.uppercaseString;
        NSString *contentType = [[request valueForHTTPHeaderField:@"Content-Type"] lowercaseString];
        BOOL graphQLContentType = [contentType rangeOfString:@"application/graphql"].location != NSNotFound;
        NSString *reportedPath = reportedURL.path ?: @"";
        BOOL graphQLEndpoint = isGraphQLEndpointPath(reportedPath);

        if ([method isEqualToString:@"GET"]) {
            NSURL *url = request.URL;
            NSString *queryString = url.query;
            if (url != nil && queryString.length > 0 && queryString.length <= graphQLMaximumBodySize) {
                NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
                NSMutableDictionary *payload = [NSMutableDictionary new];
                for (NSURLQueryItem *item in components.queryItems) {
                    if ([item.name isEqualToString:@"query"] ||
                        [item.name isEqualToString:@"mutation"] ||
                        [item.name isEqualToString:@"subscription"] ||
                        [item.name isEqualToString:@"operationName"]) {
                        payload[item.name] = item.value;
                    }
                }
                if (addGraphQLPayloadAttributes(attributes, payload, reportedURL)) return attributes;
            }
            if (graphQLContentType || graphQLEndpoint) {
                BSGLogDebug(@"GraphQL request not detected: method=%@ endpoint=%@ reason=GET request had GraphQL hint but no readable query parameter",
                            method,
                            reportedURL.path.length > 0 ? reportedURL.path : @"/");
            }
            return attributes;
        }
        if (![method isEqualToString:@"POST"]) return attributes;
        if (request.HTTPBodyStream != nil) {
            BSGLogDebug(@"GraphQL request was not inspected: streamed POST bodies are unsupported; request remains category=network");
            return attributes;
        }
        BOOL jsonContentType = contentType.length == 0 || [contentType rangeOfString:@"json"].location != NSNotFound;
        if (!jsonContentType && !graphQLContentType && !graphQLEndpoint) {
            BSGLogDebug(@"GraphQL request was not inspected: non-JSON Content-Type");
            return attributes;
        }
        NSData *body = request.HTTPBody;
        if (body.length == 0) {
            if (graphQLContentType || graphQLEndpoint) {
                BSGLogDebug(@"GraphQL request not detected: method=%@ endpoint=%@ reason=GraphQL hint present but request body is empty",
                            method,
                            reportedURL.path.length > 0 ? reportedURL.path : @"/");
            }
            return attributes;
        }
        if (body.length > graphQLMaximumBodySize) {
            BSGLogDebug(@"GraphQL request was not inspected: body size %lu exceeds the %lu-byte limit",
                        (unsigned long)body.length,
                        (unsigned long)graphQLMaximumBodySize);
            return attributes;
        }

        if (graphQLContentType) {
            NSString *document = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
            addGraphQLDocumentAttributes(attributes, document, nil, nil, reportedURL);
            return attributes;
        }

        if (dataContainsGraphQLJSONKey(body)) {
            BSGLogDebug(@"GraphQL JSON candidate found: method=POST endpoint=%@ bodyBytes=%lu",
                        reportedURL.path.length > 0 ? reportedURL.path : @"/",
                        (unsigned long)body.length);
            id json = [NSJSONSerialization JSONObjectWithData:body options:0 error:nil];
            if ([json isKindOfClass:NSDictionary.class]) {
                if (addGraphQLPayloadAttributes(attributes, json, reportedURL)) return attributes;
            }
            // Batches remain out of scope even when the endpoint path contains /graphql.
            if ([json isKindOfClass:NSArray.class]) return attributes;
            BSGLogDebug(@"GraphQL candidate did not expose usable operation metadata");
        }
        if (graphQLEndpoint) {
            id endpointJSON = jsonContentType
                ? [NSJSONSerialization JSONObjectWithData:body options:0 error:nil]
                : nil;
            if ([endpointJSON isKindOfClass:NSArray.class]) return attributes;
            NSString *requestedName = [endpointJSON isKindOfClass:NSDictionary.class]
                ? endpointJSON[@"operationName"]
                : nil;
            (void)requestedName;
            BSGLogDebug(@"GraphQL request not detected: method=%@ endpoint=%@ reason=/graphql endpoint body did not contain a readable GraphQL document",
                        method,
                        reportedURL.path.length > 0 ? reportedURL.path : @"/");
        }
        if (attributes.count == 0) {
            BSGLogDebug(@"GraphQL request not detected: method=%@ endpoint=%@ contentType=%@ reason=no GraphQL URL/content-type/query body signal; request remains category=network",
                        method,
                        reportedURL.path.length > 0 ? reportedURL.path : @"/",
                        contentType.length > 0 ? contentType : @"none");
        }
    } @catch (NSException *exception) {
        BSGLogDebug(@"Could not inspect request for GraphQL attributes: %@", exception.reason);
        [attributes removeAllObjects];
    }
    return attributes;
}

NSString *
SpanAttributesProvider::graphQLSpanName(NSURL *reportedURL, NSDictionary *attributes) noexcept {
    (void)reportedURL;
    if (![attributes[@"bugsnag.span.category"] isEqualToString:@"graphql"]) return nil;
    NSString *operationType = attributes[@"graphql.operation.type"] ?: @"query";
    NSString *operationName = attributes[@"graphql.operation.name"] ?: @"<anonymous>";
    return [NSString stringWithFormat:@"[GraphQL] %@:%@", operationType, operationName];
}


NSMutableDictionary *
SpanAttributesProvider::networkSpanUrlAttributes(NSURL *url, NSError *encounteredError) noexcept {
    BSGLogTrace(@"SpanAttributesProvider::networkSpanUrlAttributes(%@)", url);
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    NSString *urlString = url.absoluteString;
    if (urlString != nil) {
        attributes[@"http.url"] = urlString;
    }
    if (encounteredError != nil) {
        BSGLogTrace(@"SpanAttributesProvider::networkSpanUrlAttributes: Caller encountered error \"%@\". Adding instrumentation_message attribute", encounteredError.description);
        [attributes addEntriesFromDictionary:internalErrorAttributes(encounteredError)];
    }
    return attributes;
}

NSMutableDictionary *
SpanAttributesProvider::internalErrorAttributes(NSError *encounteredError) noexcept {
    BSGLogTrace(@"SpanAttributesProvider::errorAttributes");
    auto attributes = [NSMutableDictionary new];
    if (encounteredError != nil) {
        attributes[@"bugsnag.instrumentation_message"] = encounteredError.description;
    }
    return attributes;
}

NSMutableDictionary *
SpanAttributesProvider::appStartPhaseSpanAttributes(NSString *phase) noexcept {
    return @{
        @"bugsnag.span.category": @"app_start_phase",
        @"bugsnag.phase": phase,
    }.mutableCopy;
}

NSMutableDictionary *
SpanAttributesProvider::initialAppStartSpanAttributes() noexcept {
    return @{
        @"bugsnag.span.category": @"app_start",
    }.mutableCopy;
}

NSMutableDictionary *
SpanAttributesProvider::appStartSpanAttributes(NSString *firstViewName, bool isColdLaunch) noexcept {
    NSMutableDictionary *attributes = @{
        @"bugsnag.span.category": @"app_start",
        @"bugsnag.app_start.type": isColdLaunch ? @"cold" : @"warm",
    }.mutableCopy;
    if (firstViewName != nullptr) {
        attributes[@"bugsnag.app_start.first_view_name"] = firstViewName;
    }
    return attributes;
}


NSMutableDictionary *
SpanAttributesProvider::viewLoadSpanAttributes(NSString *className, BugsnagPerformanceViewType viewType) noexcept {
    return @{
        @"bugsnag.span.category": @"view_load",
        @"bugsnag.view.name": className,
        @"bugsnag.view.type": getBugsnagPerformanceViewTypeName(viewType)
    }.mutableCopy;
}

NSMutableDictionary *
SpanAttributesProvider::preloadViewLoadSpanAttributes(NSString *className, BugsnagPerformanceViewType viewType) noexcept {
    return @{
        @"bugsnag.span.category": @"view_load",
        @"bugsnag.view.name": [NSString stringWithFormat:@"%@ (preload)", className],
        @"bugsnag.view.type": getBugsnagPerformanceViewTypeName(viewType)
    }.mutableCopy;
}

NSMutableDictionary *
SpanAttributesProvider::presentingViewLoadSpanAttributes(NSString *className, BugsnagPerformanceViewType viewType) noexcept {
    return @{
        @"bugsnag.span.category": @"view_load",
        @"bugsnag.view.name": [NSString stringWithFormat:@"%@ (presentation)", className],
        @"bugsnag.view.type": getBugsnagPerformanceViewTypeName(viewType)
    }.mutableCopy;
}

NSMutableDictionary *
SpanAttributesProvider::viewLoadPhaseSpanAttributes(NSString *className, NSString *phase) noexcept {
    return @{
        @"bugsnag.span.category": @"view_load_phase",
        @"bugsnag.view.name": className,
        @"bugsnag.phase": phase,
    }.mutableCopy;
}

NSMutableDictionary *
SpanAttributesProvider::customSpanAttributes() noexcept {
    return @{
        @"bugsnag.span.category": @"custom",
    }.mutableCopy;
}

NSMutableDictionary *
SpanAttributesProvider::sessionSpanAttributes(NSString *sessionType) noexcept {
    return @{
        @"bugsnag.span.category": BSGSpanCategoryAppSession,
        @"bugsnag.app_session.name": sanitizeSessionTypeIdentifier(sessionType ?: @""),
    }.mutableCopy;
}

NSMutableDictionary *
SpanAttributesProvider::cpuSampleAttributes(const std::vector<SystemInfoSampleData> &samples) noexcept {
    auto process = [[NSMutableArray alloc] initWithCapacity:samples.size()];
    auto mainThread = [[NSMutableArray alloc] initWithCapacity:samples.size()];
    auto monitorThread = [[NSMutableArray alloc] initWithCapacity:samples.size()];
    auto timestamps = [[NSMutableArray alloc] initWithCapacity:samples.size()];
    uint64_t processSampleCount = 0;
    double processTotal = 0;
    uint64_t mainThreadSampleCount = 0;
    double mainThreadTotal = 0;
    uint64_t monitorThreadSampleCount = 0;
    double monitorThreadTotal = 0;
    for(auto sample: samples) {
        if (!sample.hasValidData()) {
            continue;
        }
        [timestamps addObject:@(CFAbsoluteTimeToUTCNanos(sample.sampledAt))];

        if (sample.isProcessCPUPctValid()) {
            processSampleCount++;
            processTotal += sample.processCPUPct;
            [process addObject:@(sample.processCPUPct)];
        } else {
            [process addObject:@(-1)];
        }

        if (sample.isMainThreadCPUPctValid()) {
            mainThreadSampleCount++;
            mainThreadTotal += sample.mainThreadCPUPct;
            [mainThread addObject:@(sample.mainThreadCPUPct)];
        } else {
            [mainThread addObject:@(-1)];
        }

        if (sample.isMonitorThreadCPUPctValid()) {
            monitorThreadSampleCount++;
            monitorThreadTotal += sample.monitorThreadCPUPct;
            [monitorThread addObject:@(sample.monitorThreadCPUPct)];
        } else {
            [monitorThread addObject:@(-1)];
        }
    }

    NSMutableDictionary *result = [NSMutableDictionary new];

    if (timestamps.count < 2 || processSampleCount == 0) {
        return result;
    }

    result[@"bugsnag.system.cpu_measures_timestamps"] = timestamps;

    if(processSampleCount > 0) {
        result[@"bugsnag.system.cpu_measures_total"] = process;
        result[@"bugsnag.system.cpu_mean_total"] = @(processTotal / (double)processSampleCount);
    }

    if(mainThreadSampleCount > 0) {
        result[@"bugsnag.system.cpu_measures_main_thread"] = mainThread;
        result[@"bugsnag.system.cpu_mean_main_thread"] = @(mainThreadTotal / (double)mainThreadSampleCount);
    }

    if(monitorThreadSampleCount > 0) {
        result[@"bugsnag.system.cpu_measures_overhead"] = monitorThread;
        result[@"bugsnag.system.cpu_mean_overhead"] = @(monitorThreadTotal / (double)monitorThreadSampleCount);
    }

    return result;
}

NSMutableDictionary *
SpanAttributesProvider::sessionCPUSampleAttributes(const std::vector<SystemInfoSampleData> &samples,
                                                   CFAbsoluteTime endTime) noexcept {
    uint64_t processSampleCount = 0;
    double processTotal = 0;
    double processMin = 0;
    double processMax = 0;
    uint64_t mainThreadSampleCount = 0;
    double mainThreadTotal = 0;
    double mainThreadMin = 0;
    double mainThreadMax = 0;
    uint64_t monitorThreadSampleCount = 0;
    double monitorThreadTotal = 0;
    double monitorThreadMin = 0;
    double monitorThreadMax = 0;

    for (const auto &sample: samples) {
        if (!sample.isSampledAtValid()) {
            continue;
        }

        if (sample.isProcessCPUPctValid()) {
            if (processSampleCount == 0) {
                processMin = sample.processCPUPct;
                processMax = sample.processCPUPct;
            } else {
                processMin = std::min(processMin, sample.processCPUPct);
                processMax = std::max(processMax, sample.processCPUPct);
            }
            processSampleCount++;
            processTotal += sample.processCPUPct;
        }

        if (sample.isMainThreadCPUPctValid()) {
            if (mainThreadSampleCount == 0) {
                mainThreadMin = sample.mainThreadCPUPct;
                mainThreadMax = sample.mainThreadCPUPct;
            } else {
                mainThreadMin = std::min(mainThreadMin, sample.mainThreadCPUPct);
                mainThreadMax = std::max(mainThreadMax, sample.mainThreadCPUPct);
            }
            mainThreadSampleCount++;
            mainThreadTotal += sample.mainThreadCPUPct;
        }

        if (sample.isMonitorThreadCPUPctValid()) {
            if (monitorThreadSampleCount == 0) {
                monitorThreadMin = sample.monitorThreadCPUPct;
                monitorThreadMax = sample.monitorThreadCPUPct;
            } else {
                monitorThreadMin = std::min(monitorThreadMin, sample.monitorThreadCPUPct);
                monitorThreadMax = std::max(monitorThreadMax, sample.monitorThreadCPUPct);
            }
            monitorThreadSampleCount++;
            monitorThreadTotal += sample.monitorThreadCPUPct;
        }
    }

    NSMutableDictionary *result = [NSMutableDictionary new];
    if (processSampleCount == 0) {
        return result;
    }

    NSNumber *endTimestamp = @(CFAbsoluteTimeToUTCNanos(endTime));
    double processMean = processTotal / (double)processSampleCount;
    result[@"bugsnag.system.cpu_measures_timestamps"] = @[endTimestamp];
    result[@"bugsnag.system.cpu_measures_total"] = @[@(processMean)];
    result[@"bugsnag.system.cpu_mean_total"] = @(processMean);
    result[@"bugsnag.system.cpu_min_total"] = @(processMin);
    result[@"bugsnag.system.cpu_max_total"] = @(processMax);

    if (mainThreadSampleCount > 0) {
        double mainThreadMean = mainThreadTotal / (double)mainThreadSampleCount;
        result[@"bugsnag.system.cpu_measures_main_thread"] = @[@(mainThreadMean)];
        result[@"bugsnag.system.cpu_mean_main_thread"] = @(mainThreadMean);
        result[@"bugsnag.system.cpu_min_main_thread"] = @(mainThreadMin);
        result[@"bugsnag.system.cpu_max_main_thread"] = @(mainThreadMax);
    }

    if (monitorThreadSampleCount > 0) {
        double monitorThreadMean = monitorThreadTotal / (double)monitorThreadSampleCount;
        result[@"bugsnag.system.cpu_measures_overhead"] = @[@(monitorThreadMean)];
        result[@"bugsnag.system.cpu_mean_overhead"] = @(monitorThreadMean);
        result[@"bugsnag.system.cpu_min_overhead"] = @(monitorThreadMin);
        result[@"bugsnag.system.cpu_max_overhead"] = @(monitorThreadMax);
    }

    return result;
}

NSMutableDictionary *
SpanAttributesProvider::memorySampleAttributes(const std::vector<SystemInfoSampleData> &samples) noexcept {
    auto memory = [[NSMutableArray alloc] initWithCapacity:samples.size()];
    auto timestamps = [[NSMutableArray alloc] initWithCapacity:samples.size()];
    uint64_t memorySampleCount = 0;
    uint64_t memoryUseTotal = 0;
    uint64_t memorySize = 0;

    for(auto sample: samples) {
        if (!sample.isSampledAtValid()) {
            continue;
        }

        if (!sample.isPhysicalMemoryInUseValid()) {
            // In this case we're only recording one metric, so no sense in recording just a failed reading.
            continue;
        }

        memorySize = sample.physicalMemoryBytesTotal;
        [timestamps addObject:@(CFAbsoluteTimeToUTCNanos(sample.sampledAt))];

        memorySampleCount++;
        memoryUseTotal += sample.physicalMemoryBytesInUse;
        [memory addObject:@(sample.physicalMemoryBytesInUse)];
    }

    if (memorySampleCount < 2) {
        return [NSMutableDictionary new];
    }

    return @{
        @"bugsnag.system.memory.timestamps": timestamps,
        @"bugsnag.system.memory.spaces.device.size": @(memorySize),
        @"bugsnag.system.memory.spaces.device.used": memory,
        @"bugsnag.system.memory.spaces.device.mean": @(memoryUseTotal / memorySampleCount),
    }.mutableCopy;
}

// ---------------------------------------------------------------------------
// Accumulator-based overloads (no ring-buffer data loss for long sessions)
// ---------------------------------------------------------------------------

NSMutableDictionary *
SpanAttributesProvider::sessionCPUSampleAttributes(const SessionMetricsAccumulator &acc,
                                                   CFAbsoluteTime endTime) noexcept {
    NSMutableDictionary *result = [NSMutableDictionary new];
    if (!acc.processCPU.hasData()) {
        return result;
    }

    NSNumber *endTimestamp = @(CFAbsoluteTimeToUTCNanos(endTime));
    const double processMean      = acc.processCPU.mean();
    result[@"bugsnag.system.cpu_measures_timestamps"] = @[endTimestamp];
    result[@"bugsnag.system.cpu_measures_total"]      = @[@(processMean)];
    result[@"bugsnag.system.cpu_mean_total"]          = @(processMean);
    result[@"bugsnag.system.cpu_min_total"]           = @(acc.processCPU.min);
    result[@"bugsnag.system.cpu_max_total"]           = @(acc.processCPU.max);

    if (acc.mainThreadCPU.hasData()) {
        const double mainMean = acc.mainThreadCPU.mean();
        result[@"bugsnag.system.cpu_measures_main_thread"] = @[@(mainMean)];
        result[@"bugsnag.system.cpu_mean_main_thread"]     = @(mainMean);
        result[@"bugsnag.system.cpu_min_main_thread"]      = @(acc.mainThreadCPU.min);
        result[@"bugsnag.system.cpu_max_main_thread"]      = @(acc.mainThreadCPU.max);
    }

    if (acc.monitorThreadCPU.hasData()) {
        const double monitorMean = acc.monitorThreadCPU.mean();
        result[@"bugsnag.system.cpu_measures_overhead"] = @[@(monitorMean)];
        result[@"bugsnag.system.cpu_mean_overhead"]     = @(monitorMean);
        result[@"bugsnag.system.cpu_min_overhead"]      = @(acc.monitorThreadCPU.min);
        result[@"bugsnag.system.cpu_max_overhead"]      = @(acc.monitorThreadCPU.max);
    }

    return result;
}

NSMutableDictionary *
SpanAttributesProvider::sessionMemorySampleAttributes(const SessionMetricsAccumulator &acc,
                                                      CFAbsoluteTime endTime) noexcept {
    if (!acc.memory.hasData()) {
        return [NSMutableDictionary new];
    }

    NSNumber *endTimestamp = @(CFAbsoluteTimeToUTCNanos(endTime));
    return @{
        @"bugsnag.system.memory.timestamps":              @[endTimestamp],
        @"bugsnag.system.memory.spaces.device.size":      @(acc.memory.lastTotalSize),
        @"bugsnag.system.memory.spaces.device.used":      @[@(acc.memory.mean())],
        @"bugsnag.system.memory.spaces.device.mean":      @(acc.memory.mean()),
        @"bugsnag.system.memory.spaces.device.min":       @(acc.memory.min),
        @"bugsnag.system.memory.spaces.device.max":       @(acc.memory.max),
    }.mutableCopy;
}

// ---------------------------------------------------------------------------

NSMutableDictionary *
SpanAttributesProvider::sessionMemorySampleAttributes(const std::vector<SystemInfoSampleData> &samples,
                                                      CFAbsoluteTime endTime) noexcept {
    uint64_t memorySampleCount = 0;
    uint64_t memoryUseTotal = 0;
    uint64_t memorySize = 0;
    uint64_t memoryMin = 0;
    uint64_t memoryMax = 0;

    for (const auto &sample: samples) {
        if (!sample.isSampledAtValid() || !sample.isPhysicalMemoryInUseValid()) {
            continue;
        }

        memorySize = sample.physicalMemoryBytesTotal;
        if (memorySampleCount == 0) {
            memoryMin = sample.physicalMemoryBytesInUse;
            memoryMax = sample.physicalMemoryBytesInUse;
        } else {
            memoryMin = std::min(memoryMin, sample.physicalMemoryBytesInUse);
            memoryMax = std::max(memoryMax, sample.physicalMemoryBytesInUse);
        }

        memorySampleCount++;
        memoryUseTotal += sample.physicalMemoryBytesInUse;
    }

    if (memorySampleCount == 0) {
        return [NSMutableDictionary new];
    }

    uint64_t memoryMean = memoryUseTotal / memorySampleCount;
    NSNumber *endTimestamp = @(CFAbsoluteTimeToUTCNanos(endTime));
    return @{
        @"bugsnag.system.memory.timestamps": @[endTimestamp],
        @"bugsnag.system.memory.spaces.device.size": @(memorySize),
        @"bugsnag.system.memory.spaces.device.used": @[@(memoryMean)],
        @"bugsnag.system.memory.spaces.device.mean": @(memoryMean),
        @"bugsnag.system.memory.spaces.device.min": @(memoryMin),
        @"bugsnag.system.memory.spaces.device.max": @(memoryMax),
    }.mutableCopy;
}
