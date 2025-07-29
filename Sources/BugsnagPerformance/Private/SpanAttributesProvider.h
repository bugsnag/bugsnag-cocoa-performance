//
//  SpanAttributesProvider.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 21/04/2023.
//  Copyright © 2023 Bugsnag. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "BugsnagPerformanceViewType+Private.h"
#import "SystemInfoSampler.h"

namespace bugsnag {
class SpanAttributesProvider {
public:
    SpanAttributesProvider() noexcept;
    ~SpanAttributesProvider() {};
    
    NSMutableDictionary *initialNetworkSpanAttributes() noexcept;
    NSMutableDictionary *networkSpanUrlAttributes(NSURL *url, NSError *encounteredError) noexcept;
    NSMutableDictionary *networkSpanAttributes(NSURL *url, NSURLSessionTask *task, NSURLSessionTaskMetrics *metrics,
                                               NSError *encounteredError) noexcept;
    
    NSMutableDictionary *internalErrorAttributes(NSError *encounteredError) noexcept;
    
    NSMutableDictionary *appStartSpanAttributes(NSString *firstViewName, bool isColdLaunch) noexcept;
    NSMutableDictionary *appStartPhaseSpanAttributes(NSString *phase) noexcept;
    NSMutableDictionary *viewLoadSpanAttributes(NSString *className, BugsnagPerformanceViewType viewType) noexcept;
    NSMutableDictionary *preloadViewLoadSpanAttributes(NSString *className, BugsnagPerformanceViewType viewType) noexcept;
    NSMutableDictionary *presentingViewLoadSpanAttributes(NSString *className, BugsnagPerformanceViewType viewType) noexcept;
    NSMutableDictionary *viewLoadPhaseSpanAttributes(NSString *className, NSString *phase) noexcept;
    NSMutableDictionary *customSpanAttributes() noexcept;

    NSMutableDictionary *cpuSampleAttributes(const std::vector<SystemInfoSampleData> &samples) noexcept;
    NSMutableDictionary *memorySampleAttributes(const std::vector<SystemInfoSampleData> &samples) noexcept;

    static NSString *httpUrlAttributeKey();
};
}
