//
//  OtlpPackage.h
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 04.11.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

namespace bugsnag {
class OtlpPackage {
public:
    OtlpPackage(const NSData *payload, const NSDictionary *headers) noexcept
    : payload_(payload)
    , headers_(headers)
    {}

    void fillURLRequest(NSMutableURLRequest *request) const noexcept;

private:
    OtlpPackage() = delete;

    const NSData *payload_;
    const NSDictionary *headers_;
};
}
