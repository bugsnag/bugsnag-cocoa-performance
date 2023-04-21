//
//  SpanAttributesProvider.mm
//  BugsnagPerformance
//
//  Created by Robert B on 21/04/2023.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "SpanAttributesProvider.h"
#import <Foundation/Foundation.h>
#import "Utils.h"
#if TARGET_OS_IOS
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#endif

using namespace bugsnag;

static NSDictionary *accessTechnologyMappingDictionary();

// https://stackoverflow.com/questions/58426438/what-is-key-in-cttelephonynetworkinfo-servicesubscribercellularproviders-and-c
static NSString * const networkSubtypeKey = @"0000000100000001";
static NSString * const connectionTypeCell = @"cell";
static NSDictionary * const accessTechnologyMapping = accessTechnologyMappingDictionary();

SpanAttributesProvider::SpanAttributesProvider() noexcept {};

static NSString *getHTTPFlavour(NSURLSessionTaskMetrics *metrics) {
    if (metrics.transactionMetrics.count > 0) {
        NSString *protocolName = metrics.transactionMetrics[0].networkProtocolName;
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
        if (metrics.transactionMetrics.count > 0 && metrics.transactionMetrics[0].cellular) {
            return connectionTypeCell;
        }
    }
    return @"wifi";
}

static NSDictionary *accessTechnologyMappingDictionary() {
    NSMutableDictionary *result = [@{
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
    } mutableCopy];
    if (@available(iOS 14.1, *)) {
        result[CTRadioAccessTechnologyNRNSA] = @"nrnsa";
        result[CTRadioAccessTechnologyNR] = @"nr";
    }
    return result;
}

static NSString *getConnectionSubtype(NSString *networkType) {
    if ([networkType isEqual:connectionTypeCell]) {
#if TARGET_OS_IOS
        NSString *accessTechnology;
        if (@available(iOS 12.0, *)) {
            accessTechnology = [[CTTelephonyNetworkInfo new].serviceCurrentRadioAccessTechnology objectForKey:networkSubtypeKey];
        } else {
            accessTechnology = [CTTelephonyNetworkInfo new].currentRadioAccessTechnology;
        }
        if (accessTechnology) {
            return accessTechnologyMapping[accessTechnology];
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

NSDictionary *
SpanAttributesProvider::networkSpanAttributes(NSURLSessionTask *task,
                                              NSURLSessionTaskMetrics *metrics) noexcept {
    auto httpResponse = BSGDynamicCast<NSHTTPURLResponse>(task.response);
    auto attributes = [NSMutableDictionary new];
    attributes[@"bugsnag.span.category"] = @"network";
    attributes[@"http.flavor"] = getHTTPFlavour(metrics);
    attributes[@"http.method"] = task.originalRequest.HTTPMethod;
    attributes[@"http.status_code"] = httpResponse ? @(httpResponse.statusCode) : @0;
    attributes[@"http.url"] = task.originalRequest.URL.absoluteString;
    attributes[@"net.host.connection.type"] = getConnectionType(task, metrics);
    attributes[@"net.host.connection.subtype"] = getConnectionSubtype(attributes[@"net.host.connection.type"]);
    addNonZero(attributes, @"http.request_content_length", @(task.countOfBytesSent));
    addNonZero(attributes, @"http.response_content_length", @(task.countOfBytesReceived));
    return attributes;
}


