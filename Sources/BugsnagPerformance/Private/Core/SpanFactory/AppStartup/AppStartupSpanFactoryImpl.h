//
//  AppStartupSpanFactoryImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 19/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "AppStartupSpanFactory.h"
#import "../../Attributes/SpanAttributesProvider.h"
#import "../Plain/PlainSpanFactory.h"

namespace bugsnag {

class AppStartupSpanFactoryImpl: public AppStartupSpanFactory {
public:
    AppStartupSpanFactoryImpl(std::shared_ptr<PlainSpanFactory> plainSpanFactory,
                              std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) noexcept
    : plainSpanFactory_(plainSpanFactory)
    , spanAttributesProvider_(spanAttributesProvider) {}
    
    BugsnagPerformanceSpan *startAppStartSpan(NSString *name,
                                              const SpanOptions &options,
                                              NSDictionary *attributes,
                                              NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept;
    BugsnagPerformanceSpan *startAppStartOverallSpan(CFAbsoluteTime startTime, bool isColdLaunch, NSString *firstViewName) noexcept;
    BugsnagPerformanceSpan *startPreMainSpan(CFAbsoluteTime startTime, BugsnagPerformanceSpanContext *parentContext) noexcept;
    BugsnagPerformanceSpan *startPostMainSpan(CFAbsoluteTime startTime, BugsnagPerformanceSpanContext *parentContext) noexcept;
    BugsnagPerformanceSpan *startUIInitSpan(CFAbsoluteTime startTime,
                                            BugsnagPerformanceSpanContext *parentContext,
                                            NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept;
    
private:
    std::shared_ptr<PlainSpanFactory> plainSpanFactory_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    
    BugsnagPerformanceSpan *startAppStartPhaseSpan(NSString *phase,
                                                   CFAbsoluteTime startTime,
                                                   BugsnagPerformanceSpanContext *parentContext,
                                                   NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept;
    
    AppStartupSpanFactoryImpl() = delete;
};
}
