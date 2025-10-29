//
//  OtlpPackage.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 04.11.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#pragma once

#import <Foundation/Foundation.h>
#import <memory>

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

/**
 * Contains the information necessary to send an HTTP request to the server.
 */
class OtlpPackage {
public:
    OtlpPackage(const dispatch_time_t ts, const NSData *payload, const NSDictionary *headers) noexcept
    : timestamp(ts)
    , payload_(payload)
    , headers_(headers)
    {}

    /**
     * Fill a request with everything necessary to send to the server.
     */
    void fillURLRequest(NSMutableURLRequest *request) const noexcept;

    NSData *serialize() noexcept;

    const dispatch_time_t timestamp{0};

    uint64_t uncompressedContentLength();

private:
    friend bool operator==(const OtlpPackage &lhs, const OtlpPackage &rhs);
    OtlpPackage() = delete;

    const NSData *payload_{nil};
    const NSDictionary *headers_{nil};

public: // For testing only
    const NSData *getPayloadForUnitTest() {return payload_;}
    const NSDictionary *getHeadersForUnitTest() {return headers_;}
};

inline bool operator==(const OtlpPackage &lhs, const OtlpPackage &rhs) {
    return lhs.timestamp == rhs.timestamp &&
    [lhs.headers_ isEqualToDictionary:(NSDictionary * _Nonnull)rhs.headers_] &&
    [lhs.payload_ isEqualToData:(NSData * _Nonnull)rhs.payload_];
}

/**
 * Deserialize an Otlp package. Returns a null pointer if the data is corrupted.
 */
std::unique_ptr<OtlpPackage> deserializeOtlpPackage(const dispatch_time_t ts, const NSData *fileContents) noexcept;

}

NS_ASSUME_NONNULL_END
