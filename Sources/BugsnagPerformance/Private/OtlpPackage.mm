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

OtlpPackage::OtlpPackage(const NSData *payload, const NSDictionary *headers) noexcept
: payload_(payload)
, headers_(headersWithIntegrityDigest(payload, headers))
{}

void OtlpPackage::fillURLRequest(NSMutableURLRequest *request) const noexcept {
    request.HTTPMethod = @"POST";
    request.HTTPBody = (NSData *)payload_;
    for (NSString *key in headers_) {
        [request setValue:headers_[key] forHTTPHeaderField:key];
    }
}
