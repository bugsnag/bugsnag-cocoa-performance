//
//  OtlpPackage.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 04.11.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "OtlpPackage.h"

#import <CommonCrypto/CommonCrypto.h>

using namespace bugsnag;

static NSDictionary * headersWithIntegrityDigest(const NSData *payload, const NSDictionary *headers) {
    if (!payload) {
        return nil;
    }

    unsigned char md[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(payload.bytes, (CC_LONG)payload.length, md);
    auto digest = [NSString stringWithFormat:@"sha1 %02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                   md[0], md[1], md[2], md[3], md[4],
                   md[5], md[6], md[7], md[8], md[9],
                   md[10], md[11], md[12], md[13], md[14],
                   md[15], md[16], md[17], md[18], md[19]];

    NSMutableDictionary *mutableHeaders = headers.mutableCopy;
    mutableHeaders[@"Bugsnag-Integrity"] = digest;

    return mutableHeaders;
}

OtlpPackage::OtlpPackage(const dispatch_time_t ts,
                         const NSData *payload,
                         const NSDictionary *headers) noexcept
: timestamp(ts)
, payload_(payload)
, headers_(headersWithIntegrityDigest(payload, headers))
{}

static int getPayloadOffset(const NSData *data) {
    auto endOfHeaders = [@"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    auto range = [data rangeOfData:endOfHeaders options:0 range:NSMakeRange(0, data.length)];
    if (range.location == NSNotFound) {
        return -1;
    }
    return (int)(range.location + range.length);
}

static NSData *deserializePayload(const NSData *data) {
    auto payloadOffset = getPayloadOffset(data);
    if (payloadOffset < 0) {
        return nullptr;
    }
    auto offset = (NSUInteger)payloadOffset;
    return [data subdataWithRange:NSMakeRange(offset, data.length - offset)];
}

static NSDictionary *deserializeHeaders(const NSData *data) {
    auto payloadOffset = getPayloadOffset(data);
    if (payloadOffset < 0) {
        return nullptr;
    }
    auto headerStr = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, (NSUInteger)payloadOffset)]
                                           encoding:NSUTF8StringEncoding];
    auto headers = [NSMutableDictionary new];

    NSError *error;
    NSString *pattern = @"(\\S+)\\s*:\\s*(\\S+)";
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];

    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:headerStr options:0 range:NSMakeRange(0, headerStr.length)];

    for (NSTextCheckingResult *match in matches) {
        headers[[headerStr substringWithRange:[match rangeAtIndex:1]]] = [headerStr substringWithRange:[match rangeAtIndex:2]];
    }

    return headers;
}

std::unique_ptr<OtlpPackage> bugsnag::deserializeOtlpPackage(const dispatch_time_t ts, const NSData *fileContents) noexcept {
    auto headers = deserializeHeaders(fileContents);
    auto payload = deserializePayload(fileContents);

    if (headers == nullptr || payload == nullptr) {
        return nullptr;
    }

    return std::make_unique<OtlpPackage>(ts, payload, headers);
}

void OtlpPackage::fillURLRequest(NSMutableURLRequest *request) const noexcept {
    request.HTTPMethod = @"POST";
    request.HTTPBody = (NSData *)payload_;
    for (NSString *key in headers_) {
        [request setValue:headers_[key] forHTTPHeaderField:key];
    }
}

NSData *OtlpPackage::serialize() noexcept {
    NSMutableString *buffer = [NSMutableString new];
    for (id key in headers_) {
        [buffer appendFormat:@"%@: %@\r\n", key, headers_[key]];
    }
    [buffer appendString:@"\r\n"];
    NSMutableData *data = [[buffer dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    [data appendData:(NSData * _Nonnull)payload_];
    return data;
}
