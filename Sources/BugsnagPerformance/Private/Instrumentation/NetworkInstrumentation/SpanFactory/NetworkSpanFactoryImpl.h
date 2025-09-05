//
//  NetworkSpanFactoryImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 02/09/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "NetworkSpanFactory.h"
#import "../../../SpanAttributesProvider.h"
#import "../../../Tracer.h"

namespace bugsnag {

class NetworkSpanFactoryImpl: public NetworkSpanFactory {
public:
    NetworkSpanFactoryImpl(std::shared_ptr<Tracer> tracer,
                           std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) noexcept
    : tracer_(tracer)
    , spanAttributesProvider_(spanAttributesProvider) {}
    
    BugsnagPerformanceSpan *startOverallNetworkSpan(NSString *httpMethod,
                                                    NSURL *url,
                                                    NSError *error) noexcept;
    
    BugsnagPerformanceSpan *startInternalErrorSpan(NSString *httpMethod,
                                                   NSError *error) noexcept;
    
private:
    std::shared_ptr<Tracer> tracer_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    
    NetworkSpanFactoryImpl() = delete;
};
}
