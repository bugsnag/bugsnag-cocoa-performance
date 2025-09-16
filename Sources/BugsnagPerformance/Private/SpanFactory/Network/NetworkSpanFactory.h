//
//  NetworkSpanFactory.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../../SpanOptions.h"

@class BugsnagPerformanceSpan;

namespace bugsnag {

class NetworkSpanFactory {
public:
    virtual BugsnagPerformanceSpan *startOverallNetworkSpan(NSString *httpMethod,
                                                            NSURL *url,
                                                            NSError *error) noexcept = 0;
    virtual BugsnagPerformanceSpan *startInternalErrorSpan(NSString *httpMethod,
                                                           NSError *error) noexcept = 0;
    virtual BugsnagPerformanceSpan *startNetworkSpan(NSString *httpMethod,
                                                     SpanOptions options,
                                                     NSDictionary *attributes) noexcept = 0;
    virtual ~NetworkSpanFactory() {}
};
}
