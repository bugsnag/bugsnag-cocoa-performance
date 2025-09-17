//
//  NetworkSpanFactoryImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NetworkSpanFactory.h"
#import "../../SpanAttributesProvider.h"
#import "../Plain/PlainSpanFactory.h"

namespace bugsnag {

class NetworkSpanFactoryImpl: public NetworkSpanFactory {
public:
    NetworkSpanFactoryImpl(std::shared_ptr<PlainSpanFactory> plainSpanFactory,
                           std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) noexcept
    : plainSpanFactory_(plainSpanFactory)
    , spanAttributesProvider_(spanAttributesProvider) {}
    
    BugsnagPerformanceSpan *startOverallNetworkSpan(NSString *httpMethod,
                                                    NSURL *url,
                                                    NSError *error) noexcept;
    
    BugsnagPerformanceSpan *startInternalErrorSpan(NSString *httpMethod,
                                                   NSError *error) noexcept;
    
    BugsnagPerformanceSpan *startNetworkSpan(NSString *httpMethod,
                                             const SpanOptions &options,
                                             NSDictionary *attributes) noexcept;
    
private:
    std::shared_ptr<PlainSpanFactory> plainSpanFactory_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    
    NetworkSpanFactoryImpl() = delete;
};
}
