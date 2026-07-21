//
//  SpanAttributesTests.m
//  BugsnagPerformance-iOSTests
//
//  Created by Karl Stenerud on 21.01.25.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "TestHelpers.h"
#import "../../Sources/BugsnagPerformance/Private/AppStateTracker.h"
#import "../../Sources/BugsnagPerformance/Private/BugsnagPerformanceImpl.h"
#import "../../Sources/BugsnagPerformance/Private/Reachability.h"
#import "../../Sources/BugsnagPerformance/Private/SpanAttributesProvider.h"

using namespace bugsnag;

@interface SpanAttributesTests : XCTestCase

@end

@implementation SpanAttributesTests

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                       URL:(NSString *)URLString
                               contentType:(NSString *)contentType
                                      body:(NSString *)body {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    request.HTTPMethod = method;
    if (contentType != nil) {
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    }
    if (body != nil) {
        request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
    }
    return request;
}

- (NSString *)graphQLJSONBodyWithOperationName:(NSString *)operationName
                                     queryName:(NSString *)queryName
                             targetByteLength:(NSUInteger)targetByteLength {
    NSMutableString *query = [NSMutableString stringWithFormat:@"query %@ { __typename }", queryName];
    NSString *body = [NSString stringWithFormat:@"{\"operationName\":\"%@\",\"query\":\"%@\"}", operationName, query];
    NSUInteger bodyLength = [body dataUsingEncoding:NSUTF8StringEncoding].length;
    if (bodyLength < targetByteLength) {
        [query appendString:[@"" stringByPaddingToLength:targetByteLength - bodyLength withString:@" " startingAtIndex:0]];
        body = [NSString stringWithFormat:@"{\"operationName\":\"%@\",\"query\":\"%@\"}", operationName, query];
    }
    return body;
}

- (NSString *)graphQLNameWithLength:(NSUInteger)length {
    return [@"A" stringByPaddingToLength:length withString:@"A" startingAtIndex:0];
}

- (void)assertGraphQLRequest:(NSURLRequest *)request
               operationType:(NSString *)operationType
               operationName:(NSString *)operationName
                 displayName:(NSString *)displayName
                    spanName:(NSString *)spanName {
    SpanAttributesProvider provider;
    auto attributes = provider.graphQLAttributes(request, request.URL);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"graphql");
    XCTAssertEqualObjects(attributes[@"bugsnag.span.first_class"], @YES);
    XCTAssertEqualObjects(attributes[@"graphql.operation.type"], operationType);
    XCTAssertEqualObjects(attributes[@"graphql.operation.name"], operationName);
    XCTAssertEqualObjects(attributes[@"display_name"], displayName);
    XCTAssertEqualObjects(provider.graphQLSpanName(request.URL, attributes), spanName);
}

- (void)assertNotGraphQLRequest:(NSURLRequest *)request {
    SpanAttributesProvider provider;
    auto attributes = provider.graphQLAttributes(request, request.URL);
    XCTAssertEqual(0U, attributes.count);
    XCTAssertNil(provider.graphQLSpanName(request.URL, attributes));
}

- (void)testGraphQLPostJsonNamedQueryDetected {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:@"{\"operationName\":\"BugsnagGetUser\",\"query\":\"query BugsnagGetUser { user { id name } }\"}"];

    [self assertGraphQLRequest:request
                 operationType:@"query"
                 operationName:@"BugsnagGetUser"
                   displayName:@"query /graphql (BugsnagGetUser)"
                      spanName:@"[GraphQL] query:BugsnagGetUser"];
}

- (void)testGraphQLPostJsonNamedMutationDetected {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:@"{\"operationName\":\"UpdateCart\",\"query\":\"mutation UpdateCart { updateCart { id } }\"}"];

    [self assertGraphQLRequest:request
                 operationType:@"mutation"
                 operationName:@"UpdateCart"
                   displayName:@"mutation /graphql (UpdateCart)"
                      spanName:@"[GraphQL] mutation:UpdateCart"];
}

- (void)testGraphQLPostJsonNamedSubscriptionDetected {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:@"{\"operationName\":\"BugsnagMessageSubscription\",\"query\":\"subscription BugsnagMessageSubscription { messageAdded { id text } }\"}"];

    [self assertGraphQLRequest:request
                 operationType:@"subscription"
                 operationName:@"BugsnagMessageSubscription"
                   displayName:@"subscription /graphql (BugsnagMessageSubscription)"
                      spanName:@"[GraphQL] subscription:BugsnagMessageSubscription"];
}

- (void)testGraphQLGetQueryParametersDetected {
    NSURLRequest *request = [self requestWithMethod:@"GET"
                                                URL:@"https://api.example.com/graphql?operationName=BugsnagGetQuery&query=query%20BugsnagGetQuery%20%7B%20__typename%20%7D"
                                        contentType:nil
                                               body:nil];

    [self assertGraphQLRequest:request
                 operationType:@"query"
                 operationName:@"BugsnagGetQuery"
                   displayName:@"query /graphql (BugsnagGetQuery)"
                      spanName:@"[GraphQL] query:BugsnagGetQuery"];
}

- (void)testGraphQLApplicationGraphQLContentTypeDetected {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/graphql"
                                               body:@"query BugsnagApplicationGraphQL { __typename }"];

    [self assertGraphQLRequest:request
                 operationType:@"query"
                 operationName:@"BugsnagApplicationGraphQL"
                   displayName:@"query /graphql (BugsnagApplicationGraphQL)"
                      spanName:@"[GraphQL] query:BugsnagApplicationGraphQL"];
}

- (void)testAnonymousGraphQLQueryUsesAnonymousSpanName {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:@"{\"query\":\"query { viewer { id } }\"}"];

    SpanAttributesProvider provider;
    auto attributes = provider.graphQLAttributes(request, request.URL);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"graphql");
    XCTAssertEqualObjects(attributes[@"bugsnag.span.first_class"], @YES);
    XCTAssertEqualObjects(attributes[@"graphql.operation.type"], @"query");
    XCTAssertNil(attributes[@"graphql.operation.name"]);
    XCTAssertEqualObjects(attributes[@"display_name"], @"query /graphql");
    XCTAssertEqualObjects(provider.graphQLSpanName(request.URL, attributes), @"[GraphQL] query:<anonymous>");
}

- (void)testOperationNameFieldTakesPriority {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:@"{\"operationName\":\"SelectedOperation\",\"query\":\"query IgnoredOperation { viewer { id } } query SelectedOperation { viewer { name } }\"}"];

    [self assertGraphQLRequest:request
                 operationType:@"query"
                 operationName:@"SelectedOperation"
                   displayName:@"query /graphql (SelectedOperation)"
                      spanName:@"[GraphQL] query:SelectedOperation"];
}

- (void)testRestJsonBodyIsNotGraphQL {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/rest/users/123"
                                        contentType:@"application/json"
                                               body:@"{\"action\":\"get\",\"userId\":\"123\"}"];

    [self assertNotGraphQLRequest:request];
}

- (void)testGraphQLGetEndpointWithoutQueryParameterIsNotDetected {
    NSURLRequest *request = [self requestWithMethod:@"GET"
                                                URL:@"https://api.example.com/graphql?operationName=GetUser"
                                        contentType:nil
                                               body:nil];

    [self assertNotGraphQLRequest:request];
}

- (void)testGraphQLEndpointWithoutReadableQueryIsNotDetected {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:@"{\"operationName\":\"GetUser\"}"];

    [self assertNotGraphQLRequest:request];
}

- (void)testGraphQLEndpointWithEmptyBodyIsNotDetected {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:nil];

    [self assertNotGraphQLRequest:request];
}

- (void)testMalformedJSONBodyIsNotDetected {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:@"{\"operationName\":\"Broken\",\"query\":\"query Broken { __typename }\""];

    [self assertNotGraphQLRequest:request];
}

- (void)testGraphQLJSONKeyWithNonStringValueIsNotDetected {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:@"{\"query\":{\"nested\":\"not a GraphQL document\"},\"operationName\":\"NotAStringQuery\"}"];

    [self assertNotGraphQLRequest:request];
}

- (void)testNonGraphQLNonJSONContentTypeIsNotInspected {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/rest/search"
                                        contentType:@"text/plain"
                                               body:@"{\"operationName\":\"Search\",\"query\":\"query Search { __typename }\"}"];

    [self assertNotGraphQLRequest:request];
}

- (void)testGraphQLBatchArrayIsSkipped {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:@"[{\"operationName\":\"One\",\"query\":\"query One { __typename }\"},{\"operationName\":\"Two\",\"query\":\"query Two { __typename }\"}]"];

    [self assertNotGraphQLRequest:request];
}

- (void)testGraphQLStreamedBodyIsSkipped {
    NSMutableURLRequest *request = [self requestWithMethod:@"POST"
                                                       URL:@"https://api.example.com/graphql"
                                               contentType:@"application/json"
                                                      body:nil];
    NSData *body = [@"{\"operationName\":\"Streamed\",\"query\":\"query Streamed { __typename }\"}" dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBodyStream = [NSInputStream inputStreamWithData:body];

    [self assertNotGraphQLRequest:request];
}

- (void)testGraphQLLargeBodyIsSkipped {
    NSMutableString *largeQuery = [NSMutableString stringWithString:@"query LargeBody { "];
    for (NSUInteger index = 0; index < 70000; index++) {
        [largeQuery appendString:@"a"];
    }
    [largeQuery appendString:@" }"];
    NSString *body = [NSString stringWithFormat:@"{\"operationName\":\"LargeBody\",\"query\":\"%@\"}", largeQuery];
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:body];

    [self assertNotGraphQLRequest:request];
}

- (void)testGraphQLBodyAtMaximumInspectionSizeIsDetected {
    NSString *body = [self graphQLJSONBodyWithOperationName:@"BodyLimitExact"
                                                  queryName:@"BodyLimitExact"
                                          targetByteLength:64 * 1024];
    XCTAssertEqual((NSUInteger)(64 * 1024), [body dataUsingEncoding:NSUTF8StringEncoding].length);
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:body];

    [self assertGraphQLRequest:request
                 operationType:@"query"
                 operationName:@"BodyLimitExact"
                   displayName:@"query /graphql (BodyLimitExact)"
                      spanName:@"[GraphQL] query:BodyLimitExact"];
}

- (void)testGraphQLBodyOverMaximumInspectionSizeIsSkipped {
    NSString *body = [self graphQLJSONBodyWithOperationName:@"BodyLimitExceeded"
                                                  queryName:@"BodyLimitExceeded"
                                          targetByteLength:(64 * 1024) + 1];
    XCTAssertEqual((NSUInteger)(64 * 1024) + 1, [body dataUsingEncoding:NSUTF8StringEncoding].length);
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:body];

    [self assertNotGraphQLRequest:request];
}

- (void)testGraphQLOperationNameAtMaximumLengthIsDetected {
    NSString *operationName = [self graphQLNameWithLength:256];
    NSString *body = [NSString stringWithFormat:@"{\"operationName\":\"%@\",\"query\":\"query %@ { __typename }\"}",
                      operationName,
                      operationName];
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:body];

    [self assertGraphQLRequest:request
                 operationType:@"query"
                 operationName:operationName
                   displayName:[NSString stringWithFormat:@"query /graphql (%@)", operationName]
                      spanName:[NSString stringWithFormat:@"[GraphQL] query:%@", operationName]];
}

- (void)testGraphQLOperationNameOverMaximumLengthUsesAnonymousFallback {
    NSString *operationName = [self graphQLNameWithLength:257];
    NSString *body = [NSString stringWithFormat:@"{\"operationName\":\"%@\",\"query\":\"query %@ { __typename }\"}",
                      operationName,
                      operationName];
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:body];

    SpanAttributesProvider provider;
    auto attributes = provider.graphQLAttributes(request, request.URL);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"graphql");
    XCTAssertEqualObjects(attributes[@"bugsnag.span.first_class"], @YES);
    XCTAssertEqualObjects(attributes[@"graphql.operation.type"], @"query");
    XCTAssertNil(attributes[@"graphql.operation.name"]);
    XCTAssertEqualObjects(attributes[@"display_name"], @"query /graphql");
    XCTAssertEqualObjects(provider.graphQLSpanName(request.URL, attributes), @"[GraphQL] query:<anonymous>");
}

- (void)testGraphQLTemporaryOperationAttributesAreUsedForSpanNameOnly {
    NSMutableURLRequest *request = [self requestWithMethod:@"POST"
                                                       URL:@"https://api.example.com/graphql"
                                               contentType:@"application/json"
                                                      body:@"{\"operationName\":\"BugsnagTemporaryAttributes\",\"query\":\"query BugsnagTemporaryAttributes { __typename }\"}"];

    SpanAttributesProvider provider;
    auto attributes = provider.graphQLAttributes(request, request.URL);
    XCTAssertEqualObjects(provider.graphQLSpanName(request.URL, attributes), @"[GraphQL] query:BugsnagTemporaryAttributes");

    [attributes removeObjectsForKeys:@[@"graphql.operation.type", @"graphql.operation.name"]];
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"graphql");
    XCTAssertEqualObjects(attributes[@"bugsnag.span.first_class"], @YES);
    XCTAssertEqualObjects(attributes[@"display_name"], @"query /graphql (BugsnagTemporaryAttributes)");
    XCTAssertNil(attributes[@"graphql.operation.type"]);
    XCTAssertNil(attributes[@"graphql.operation.name"]);
}

- (void)testRestPostSubscriptionCancelIsNotGraphQL {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/subscription/cancel"
                                        contentType:@"application/json"
                                               body:@"{\"subscriptionId\":\"sub_123\",\"reason\":\"customer_request\"}"];

    [self assertNotGraphQLRequest:request];
}

- (void)testGraphQLMutationCancelSubscriptionDetected {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:@"{\"operationName\":\"CancelSubscription\",\"query\":\"mutation CancelSubscription { cancelSubscription(id: \\\"sub_123\\\") { status } }\"}"];

    [self assertGraphQLRequest:request
                 operationType:@"mutation"
                 operationName:@"CancelSubscription"
                   displayName:@"mutation /graphql (CancelSubscription)"
                      spanName:@"[GraphQL] mutation:CancelSubscription"];
}

- (void)testGraphQLMutationUpgradeSubscriptionDetected {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:@"{\"operationName\":\"UpgradeSubscription\",\"query\":\"mutation UpgradeSubscription { upgradeSubscription(planId: \\\"pro\\\") { status } }\"}"];

    [self assertGraphQLRequest:request
                 operationType:@"mutation"
                 operationName:@"UpgradeSubscription"
                   displayName:@"mutation /graphql (UpgradeSubscription)"
                      spanName:@"[GraphQL] mutation:UpgradeSubscription"];
}

- (void)testGraphQLQueryGetSubscriptionStatusDetected {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:@"{\"operationName\":\"GetSubscriptionStatus\",\"query\":\"query GetSubscriptionStatus { subscription { status } }\"}"];

    [self assertGraphQLRequest:request
                 operationType:@"query"
                 operationName:@"GetSubscriptionStatus"
                   displayName:@"query /graphql (GetSubscriptionStatus)"
                      spanName:@"[GraphQL] query:GetSubscriptionStatus"];
}

- (void)testGraphQLSubscriptionOnMessageReceivedDetected {
    NSURLRequest *request = [self requestWithMethod:@"POST"
                                                URL:@"https://api.example.com/graphql"
                                        contentType:@"application/json"
                                               body:@"{\"operationName\":\"OnMessageReceived\",\"query\":\"subscription OnMessageReceived { messageReceived { id text } }\"}"];

    [self assertGraphQLRequest:request
                 operationType:@"subscription"
                 operationName:@"OnMessageReceived"
                   displayName:@"subscription /graphql (OnMessageReceived)"
                      spanName:@"[GraphQL] subscription:OnMessageReceived"];
}

- (void)testInitialNetworkSpanAttributes {
    SpanAttributesProvider provider;
    auto attributes = provider.initialNetworkSpanAttributes();
    XCTAssertEqual(2U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"network");
    XCTAssertEqualObjects(attributes[@"http.url"], @"unknown");
}

- (void)testNetworkSpanUrlAttributes {
    SpanAttributesProvider provider;
    NSURL *url = [NSURL URLWithString:@"https://bugsnag.com"];
    NSError *error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];

    auto attributes = provider.networkSpanUrlAttributes(url, error);
    XCTAssertEqual(2U, attributes.count);
    XCTAssertEqualObjects(attributes[@"http.url"], url.absoluteString);
    XCTAssertEqualObjects(attributes[@"bugsnag.instrumentation_message"], @"Error Domain=test Code=1 \"(null)\"");

    attributes = provider.networkSpanUrlAttributes(url, nil);
    XCTAssertEqual(1U, attributes.count);
    XCTAssertEqualObjects(attributes[@"http.url"], url.absoluteString);
    XCTAssertNil(attributes[@"bugsnag.instrumentation_message"]);

    attributes = provider.networkSpanUrlAttributes(nil, error);
    XCTAssertEqual(1U, attributes.count);
    XCTAssertNil(attributes[@"http.url"]);
    XCTAssertEqualObjects(attributes[@"bugsnag.instrumentation_message"], @"Error Domain=test Code=1 \"(null)\"");

    attributes = provider.networkSpanUrlAttributes(nil, nil);
    XCTAssertEqual(0U, attributes.count);
}

- (void)testInternalErrorAttributes {
    SpanAttributesProvider provider;
    NSError *error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    auto attributes = provider.internalErrorAttributes(error);
    XCTAssertEqual(1U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.instrumentation_message"], @"Error Domain=test Code=1 \"(null)\"");
}

- (void)testAppStartPhaseSpanAttributes {
    SpanAttributesProvider provider;

    auto attributes = provider.appStartPhaseSpanAttributes(@"phase1");
    XCTAssertEqual(2U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"app_start_phase");
    XCTAssertEqualObjects(attributes[@"bugsnag.phase"], @"phase1");
}

- (void)testAppStartSpanAttributes {
    SpanAttributesProvider provider;

    auto attributes = provider.appStartSpanAttributes(@"firstView", true);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"app_start");
    XCTAssertEqualObjects(attributes[@"bugsnag.app_start.type"], @"cold");
    XCTAssertEqualObjects(attributes[@"bugsnag.app_start.first_view_name"], @"firstView");

    attributes = provider.appStartSpanAttributes(@"firstView", false);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"app_start");
    XCTAssertEqualObjects(attributes[@"bugsnag.app_start.type"], @"warm");
    XCTAssertEqualObjects(attributes[@"bugsnag.app_start.first_view_name"], @"firstView");

    attributes = provider.appStartSpanAttributes(nil, false);
    XCTAssertEqual(2U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"app_start");
    XCTAssertEqualObjects(attributes[@"bugsnag.app_start.type"], @"warm");
    XCTAssertNil(attributes[@"bugsnag.app_start.first_view_name"]);
}

- (void)testViewLoadSpanAttributes {
    SpanAttributesProvider provider;

    auto attributes = provider.viewLoadSpanAttributes(@"myView", BugsnagPerformanceViewTypeUIKit);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"UIKit");

    attributes = provider.viewLoadSpanAttributes(@"myView", BugsnagPerformanceViewTypeSwiftUI);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"SwiftUI");

    attributes = provider.viewLoadSpanAttributes(@"myView", (BugsnagPerformanceViewType)100);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"?");
}

- (void)testPreloadViewLoadSpanAttributes {
    SpanAttributesProvider provider;

    auto attributes = provider.preloadViewLoadSpanAttributes(@"myView", BugsnagPerformanceViewTypeUIKit);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView (preload)");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"UIKit");

    attributes = provider.preloadViewLoadSpanAttributes(@"myView", BugsnagPerformanceViewTypeSwiftUI);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView (preload)");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"SwiftUI");

    attributes = provider.preloadViewLoadSpanAttributes(@"myView", (BugsnagPerformanceViewType)100);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView (preload)");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"?");
}

- (void)testPresentingViewLoadSpanAttributes {
    SpanAttributesProvider provider;

    auto attributes = provider.presentingViewLoadSpanAttributes(@"myView", BugsnagPerformanceViewTypeUIKit);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView (presentation)");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"UIKit");

    attributes = provider.presentingViewLoadSpanAttributes(@"myView", BugsnagPerformanceViewTypeSwiftUI);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView (presentation)");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"SwiftUI");

    attributes = provider.presentingViewLoadSpanAttributes(@"myView", (BugsnagPerformanceViewType)100);
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView (presentation)");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.type"], @"?");
}

- (void)testViewLoadPhaseSpanAttributes {
    SpanAttributesProvider provider;

    auto attributes = provider.viewLoadPhaseSpanAttributes(@"myView", @"myPhase");
    XCTAssertEqual(3U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"view_load_phase");
    XCTAssertEqualObjects(attributes[@"bugsnag.view.name"], @"myView");
    XCTAssertEqualObjects(attributes[@"bugsnag.phase"], @"myPhase");
}

- (void)testCustomSpanAttributes {
    SpanAttributesProvider provider;

    auto attributes = provider.customSpanAttributes();
    XCTAssertEqual(1U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"custom");
}

- (void)testSessionSpanAttributes {
    SpanAttributesProvider provider;

    auto attributes = provider.sessionSpanAttributes(@"Playback");
    XCTAssertEqual(2U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.span.category"], @"app_session");
    XCTAssertEqualObjects(attributes[@"bugsnag.app_session.name"], @"Playback");
}

- (void)testSessionSpanAttributesAreSanitized {
    SpanAttributesProvider provider;

    auto attributes = provider.sessionSpanAttributes(@"Active Usage");
    XCTAssertEqualObjects(attributes[@"bugsnag.app_session.name"], @"ActiveUsage");
}

- (void)testSessionSpanAttributesFallbackForEmptyInput {
    SpanAttributesProvider provider;

    auto attributes = provider.sessionSpanAttributes(@"");
    XCTAssertEqualObjects(attributes[@"bugsnag.app_session.name"], @"Session");
}

- (void)testCPUSampleAttributesInsufficient {
    SpanAttributesProvider provider;

    // Not enough samples
    std::vector<SystemInfoSampleData> samples;
    auto attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);

    // Still not enough samples
    samples.push_back(SystemInfoSampleData(1));
    attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);

    // Both samples don't contain any valid data
    samples.push_back(SystemInfoSampleData(2));
    attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);

    // Only one sample contains valid data and we need at least 2
    samples[0].mainThreadCPUPct = 10;
    attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);
}

- (void)testCPUAttributesNilIfInvalidCPUMeanTotal {
    SpanAttributesProvider provider;
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(1),
        SystemInfoSampleData(2),
        SystemInfoSampleData(3),
    };

    auto attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);

    XCTAssertNil(attributes[@"bugsnag.system.cpu_measures_timestamps"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_measures_total"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_mean_total"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_measures_main_thread"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_mean_main_thread"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_measures_overhead"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_mean_overhead"]);
}

- (void)testCPUSampleAttributes {
    SpanAttributesProvider provider;
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(1),
        SystemInfoSampleData(2),
    };

    samples[0].processCPUPct = 10;
    samples[0].mainThreadCPUPct = 20;
    samples[0].monitorThreadCPUPct = 30;

    samples[1].processCPUPct = 40;
    samples[1].mainThreadCPUPct = 50;
    samples[1].monitorThreadCPUPct = 60;

    auto attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(7U, attributes.count);
    NSArray *expectedTimestamps = @[
        @978307201000000000,
        @978307202000000000,
    ];
    NSArray *expectedProcess = @[
        @10.0,
        @40.0,
    ];
    NSArray *expectedMainThread = @[
        @20.0,
        @50.0,
    ];
    NSArray *expectedMonitorThread = @[
        @30.0,
        @60.0,
    ];
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_timestamps"], expectedTimestamps);

    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_total"], expectedProcess);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_total"], @25.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_main_thread"], expectedMainThread);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_main_thread"], @35.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_overhead"], expectedMonitorThread);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_overhead"], @45.0);
}

- (void)testCPUSampleAttributesProcessOnly {
    SpanAttributesProvider provider;
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(11),
        SystemInfoSampleData(12),
    };

    samples[0].processCPUPct = 10;
    samples[1].processCPUPct = 40;

    auto attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(3U, attributes.count);
    NSArray *expectedTimestamps = @[
        @978307211000000000,
        @978307212000000000,
    ];
    NSArray *expectedProcess = @[
        @10.0,
        @40.0,
    ];
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_timestamps"], expectedTimestamps);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_total"], expectedProcess);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_total"], @25.0);
}

- (void)testSessionCPUSampleAttributes {
    SpanAttributesProvider provider;
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(1),
        SystemInfoSampleData(2),
    };

    samples[0].processCPUPct = 10;
    samples[0].mainThreadCPUPct = 20;
    samples[0].monitorThreadCPUPct = 30;

    samples[1].processCPUPct = 40;
    samples[1].mainThreadCPUPct = 50;
    samples[1].monitorThreadCPUPct = 60;

    auto attributes = provider.sessionCPUSampleAttributes(samples, 12);
    XCTAssertEqual(13U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_timestamps"], (@[@978307212000000000]));
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_total"], (@[@25.0]));
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_total"], @25.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_min_total"], @10.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_max_total"], @40.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_main_thread"], (@[@35.0]));
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_main_thread"], @35.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_min_main_thread"], @20.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_max_main_thread"], @50.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_overhead"], (@[@45.0]));
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_overhead"], @45.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_min_overhead"], @30.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_max_overhead"], @60.0);
}

- (void)testSessionCPUSampleAttributesWithSingleSample {
    SpanAttributesProvider provider;
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(1),
    };

    samples[0].processCPUPct = 10;
    samples[0].mainThreadCPUPct = 20;
    samples[0].monitorThreadCPUPct = 30;

    auto attributes = provider.sessionCPUSampleAttributes(samples, 11);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_timestamps"], (@[@978307211000000000]));
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_total"], (@[@10.0]));
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_total"], @10.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_min_total"], @10.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_max_total"], @10.0);
}

- (void)testCPUSampleAttributesMainThreadOnly {
    SpanAttributesProvider provider;
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(1),
        SystemInfoSampleData(2),
    };

    samples[0].mainThreadCPUPct = 20;
    samples[1].mainThreadCPUPct = 50;

    // CPU_MEAN_TOTAL not available, not sending other CPU data
    auto attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_measures_timestamps"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_measures_main_thread"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_mean_main_thread"]);
}

- (void)testCPUSampleAttributesOverheadOnly {
    SpanAttributesProvider provider;
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(1),
        SystemInfoSampleData(2),
    };

    samples[0].monitorThreadCPUPct = 30;
    samples[1].monitorThreadCPUPct = 60;

    // CPU_MEAN_TOTAL not available, not sending other CPU data
    auto attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_measures_timestamps"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_measures_overhead"]);
    XCTAssertNil(attributes[@"bugsnag.system.cpu_mean_overhead"]);
}

- (void)testCPUSampleAttributesComplex {
    SpanAttributesProvider provider;
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(1),
        SystemInfoSampleData(2),
        SystemInfoSampleData(3),
        SystemInfoSampleData(8),
        SystemInfoSampleData(9),
    };

    samples[0].processCPUPct = 10;
    samples[0].mainThreadCPUPct = -1;
    samples[0].monitorThreadCPUPct = 30;

    samples[1].processCPUPct = -1;
    samples[1].mainThreadCPUPct = -1;
    samples[1].monitorThreadCPUPct = 60;

    samples[2].processCPUPct = 40;
    samples[2].mainThreadCPUPct = 70;
    samples[2].monitorThreadCPUPct = 60;

    samples[3].processCPUPct = -1;
    samples[3].mainThreadCPUPct = -1;
    samples[3].monitorThreadCPUPct = -1;

    samples[4].processCPUPct = 70;
    samples[4].mainThreadCPUPct = 80;
    samples[4].monitorThreadCPUPct = -1;

    auto attributes = provider.cpuSampleAttributes(samples);
    XCTAssertEqual(7U, attributes.count);
    NSArray *expectedTimestamps = @[
        @978307201000000000,
        @978307202000000000,
        @978307203000000000,
        @978307209000000000,
    ];
    NSArray *expectedProcess = @[
        @10.0,
        @-1.0,
        @40.0,
        @70.0,
    ];
    NSArray *expectedMainThread = @[
        @-1.0,
        @-1.0,
        @70.0,
        @80.0,
    ];
    NSArray *expectedMonitorThread = @[
        @30.0,
        @60.0,
        @60.0,
        @-1.0,
    ];
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_timestamps"], expectedTimestamps);

    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_total"], expectedProcess);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_total"], @40.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_main_thread"], expectedMainThread);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_main_thread"], @75.0);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_measures_overhead"], expectedMonitorThread);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.cpu_mean_overhead"], @50.0);
}

- (void)testMemorySampleAttributesInsufficient {
    SpanAttributesProvider provider;

    // Not enough samples
    std::vector<SystemInfoSampleData> samples;
    auto attributes = provider.memorySampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);

    // Still not enough samples
    samples.push_back(SystemInfoSampleData(1));
    attributes = provider.memorySampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);

    // Both samples don't contain any valid data
    samples.push_back(SystemInfoSampleData(2));
    attributes = provider.memorySampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);

    // Only one sample contains valid data and we need at least 2
    samples[0].physicalMemoryBytesTotal = 10000;
    samples[1].physicalMemoryBytesInUse = 1000;
    attributes = provider.memorySampleAttributes(samples);
    XCTAssertEqual(0U, attributes.count);
}

- (void)testMemorySampleAttributesProcessOnly {
    SpanAttributesProvider provider;
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(11),
        SystemInfoSampleData(12),
    };

    samples[0].physicalMemoryBytesTotal = 100;
    samples[0].physicalMemoryBytesInUse = 80;
    samples[1].physicalMemoryBytesTotal = 100;
    samples[1].physicalMemoryBytesInUse = 50;

    auto attributes = provider.memorySampleAttributes(samples);
    XCTAssertEqual(4U, attributes.count);
    NSArray *expectedTimestamps = @[
        @978307211000000000,
        @978307212000000000,
    ];
    NSArray *expectedMemory = @[
        @80.0,
        @50.0,
    ];
    XCTAssertEqualObjects(attributes[@"bugsnag.system.memory.timestamps"], expectedTimestamps);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.memory.spaces.device.size"], @100);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.memory.spaces.device.used"], expectedMemory);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.memory.spaces.device.mean"], @65.0);
}

- (void)testSessionMemorySampleAttributes {
    SpanAttributesProvider provider;
    std::vector<SystemInfoSampleData> samples = {
        SystemInfoSampleData(11),
        SystemInfoSampleData(12),
    };

    samples[0].physicalMemoryBytesTotal = 100;
    samples[0].physicalMemoryBytesInUse = 80;
    samples[1].physicalMemoryBytesTotal = 100;
    samples[1].physicalMemoryBytesInUse = 50;

    auto attributes = provider.sessionMemorySampleAttributes(samples, 13);
    XCTAssertEqual(6U, attributes.count);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.memory.timestamps"], (@[@978307213000000000]));
    XCTAssertEqualObjects(attributes[@"bugsnag.system.memory.spaces.device.size"], @100);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.memory.spaces.device.used"], (@[@65]));
    XCTAssertEqualObjects(attributes[@"bugsnag.system.memory.spaces.device.mean"], @65);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.memory.spaces.device.min"], @50);
    XCTAssertEqualObjects(attributes[@"bugsnag.system.memory.spaces.device.max"], @80);
}

- (void)testStartSessionSpanDoesNotBecomeCurrentContext {
    auto impl = std::make_unique<bugsnag::BugsnagPerformanceImpl>(std::make_shared<bugsnag::Reachability>(), [AppStateTracker new]);

    BugsnagPerformanceSpan *sessionSpan = impl->startAppSessionSpan(@"Active Usage");
    XCTAssertEqualObjects(sessionSpan.name, @"[AppSession/ActiveUsage]");
    XCTAssertEqualObjects(sessionSpan.attributes[@"bugsnag.span.category"], @"app_session");
    XCTAssertEqualObjects(sessionSpan.attributes[@"bugsnag.app_session.name"], @"ActiveUsage");
    XCTAssertEqual(sessionSpan.firstClass, BSGTriStateYes);
    XCTAssertEqual(sessionSpan.parentId, (SpanId)0);
    XCTAssertNil(impl->currentContext());

    BugsnagPerformanceSpan *customSpan = impl->startCustomSpan(@"child");
    XCTAssertEqual(customSpan.parentId, (SpanId)0);
    XCTAssertEqual(customSpan.spanId, impl->currentContext().spanId);

    [customSpan end];
    XCTAssertNil(impl->currentContext());
    [sessionSpan end];
}


@end
