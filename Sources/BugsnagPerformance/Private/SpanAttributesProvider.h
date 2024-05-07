//
//  SpanAttributesProvider.h
//  BugsnagPerformance
//
//  Created by Robert B on 21/04/2023.
//  Copyright © 2023 Bugsnag. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "BugsnagPerformanceViewType+Private.h"

namespace bugsnag {
class SpanAttributesProvider {
public:
    SpanAttributesProvider() noexcept;
    ~SpanAttributesProvider() {};
    
    NSDictionary *networkSpanUrlAttributes(NSURL *url) noexcept;
    NSDictionary *networkSpanAttributes(NSURL *url, NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics) noexcept;
    NSDictionary *appStartSpanAttributes(NSString *firstViewName, bool isColdLaunch) noexcept;
    NSDictionary *appStartPhaseSpanAttributes(NSString *phase) noexcept;
    NSDictionary *viewLoadSpanAttributes(NSString *className, BugsnagPerformanceViewType viewType) noexcept;
    NSDictionary *preloadedViewLoadSpanAttributes(NSString *className, BugsnagPerformanceViewType viewType) noexcept;
    NSDictionary *viewLoadPhaseSpanAttributes(NSString *className, NSString *phase) noexcept;

    static NSString *httpUrlAttributeKey();
};
}
