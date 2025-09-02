//
//  NetworkSpanFactory.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BugsnagPerformanceSpan;

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

class NetworkSpanFactory {
public:
    virtual BugsnagPerformanceSpan *startOverallNetworkSpan(NSString *httpMethod,
                                                            NSURL * _Nullable url,
                                                            NSError * _Nullable error) noexcept = 0;
    virtual ~NetworkSpanFactory() {}
};
}

NS_ASSUME_NONNULL_END
