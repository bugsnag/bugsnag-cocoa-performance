//
//  OtlpPackage.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 04.11.22.
//  Copyright © 2022 Bugsnag. All rights reserved.
//

#import "OtlpPackage.h"

using namespace bugsnag;

void OtlpPackage::fillURLRequest(NSMutableURLRequest *request) const noexcept {
    request.HTTPMethod = @"POST";
    request.HTTPBody = (NSData *)payload_;
    for (NSString *key in headers_) {
        [request setValue:headers_[key] forHTTPHeaderField:key];
    }
}
