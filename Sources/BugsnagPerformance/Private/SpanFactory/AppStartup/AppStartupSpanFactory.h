//
//  AppStartupSpanFactory.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 19/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../../SpanOptions.h"

@class BugsnagPerformanceSpan;
@class BugsnagPerformanceSpanContext;
@class BugsnagPerformanceSpanCondition;

namespace bugsnag {

class AppStartupSpanFactory {
public:
    virtual BugsnagPerformanceSpan *startAppStartSpan(NSString *name,
                                                      const SpanOptions &options,
                                                      NSDictionary *attributes,
                                                      NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept = 0;
    virtual BugsnagPerformanceSpan *startAppStartOverallSpan(CFAbsoluteTime startTime, bool isColdLaunch, NSString *firstViewName) noexcept = 0;
    virtual BugsnagPerformanceSpan *startPreMainSpan(CFAbsoluteTime startTime, BugsnagPerformanceSpanContext *parentContext) noexcept = 0;
    virtual BugsnagPerformanceSpan *startPostMainSpan(CFAbsoluteTime startTime, BugsnagPerformanceSpanContext *parentContext) noexcept = 0;
    virtual BugsnagPerformanceSpan *startUIInitSpan(CFAbsoluteTime startTime,
                                                    BugsnagPerformanceSpanContext *parentContext,
                                                    NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept = 0;
    virtual ~AppStartupSpanFactory() {}
};
}
