//
//  AppStartupSpanFactoryImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 19/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "AppStartupSpanFactory.h"
#import "../../../SpanAttributesProvider.h"
#import "../../../Tracer.h"

namespace bugsnag {

class AppStartupSpanFactoryImpl: public AppStartupSpanFactory {
public:
    AppStartupSpanFactoryImpl(std::shared_ptr<Tracer> tracer,
                              std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) noexcept;
    
    BugsnagPerformanceSpan *startAppStartSpan(CFAbsoluteTime startTime, bool isColdLaunch, NSString *firstViewName) noexcept;
    BugsnagPerformanceSpan *startPreMainSpan(CFAbsoluteTime startTime, BugsnagPerformanceSpanContext *parentContext) noexcept;
    BugsnagPerformanceSpan *startPostMainSpan(CFAbsoluteTime startTime, BugsnagPerformanceSpanContext *parentContext) noexcept;
    BugsnagPerformanceSpan *startUIInitSpan(CFAbsoluteTime startTime,
                                            BugsnagPerformanceSpanContext *parentContext,
                                            NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept;
    
private:
    std::shared_ptr<Tracer> tracer_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    
    AppStartupSpanFactoryImpl() = delete;
};
}
