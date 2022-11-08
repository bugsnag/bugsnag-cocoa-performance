//
//  OtlpPackage.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 04.11.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

namespace bugsnag {

/**
 * Contains the information necessary to send an HTTP request to the server.
 */
class OtlpPackage {
public:
    OtlpPackage(const NSData *payload, const NSDictionary *headers) noexcept
    : payload_(payload)
    , headers_(headers)
    {}

    /**
     * Fill a request with everything necessary to send to the server.
     */
    void fillURLRequest(NSMutableURLRequest *request) const noexcept;

private:
    OtlpPackage() = delete;

    const NSData *payload_;
    const NSDictionary *headers_;
};
}
