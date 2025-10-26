//
//  ViewLoadSpanFactoryImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#pragma once

#import "ViewLoadSpanFactory.h"
#import "../../Attributes/SpanAttributesProvider.h"
#import "../Plain/PlainSpanFactory.h"
#import "ViewLoadSpanFactoryCallbacks.h"

namespace bugsnag {

class ViewLoadSpanFactoryImpl: public ViewLoadSpanFactory {
public:
    ViewLoadSpanFactoryImpl(std::shared_ptr<PlainSpanFactory> plainSpanFactory,
                            std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) noexcept
    : plainSpanFactory_(plainSpanFactory)
    , spanAttributesProvider_(spanAttributesProvider) {}
    
    BugsnagPerformanceSpan *startOverallViewLoadSpan(UIViewController *viewController) noexcept;
    BugsnagPerformanceSpan *startPreloadedPresentingSpan(UIViewController *viewController) noexcept;
    BugsnagPerformanceSpan *startLoadViewSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept;
    BugsnagPerformanceSpan *startViewDidLoadSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept;
    BugsnagPerformanceSpan *startViewWillAppearSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept;
    BugsnagPerformanceSpan *startViewAppearingSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept;
    BugsnagPerformanceSpan *startViewDidAppearSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept;
    BugsnagPerformanceSpan *startViewWillLayoutSubviewsSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept;
    BugsnagPerformanceSpan *startSubviewsLayoutSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept;
    BugsnagPerformanceSpan *startViewDidLayoutSubviewsSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept;
    BugsnagPerformanceSpan *startLoadingSpan(UIViewController *viewController,
                                             BugsnagPerformanceSpanContext *parentContext,
                                             NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept;
    
    BugsnagPerformanceSpan *startViewLoadSpan(BugsnagPerformanceViewType viewType,
                                              NSString *className,
                                              NSString *suffix,
                                              const SpanOptions &options,
                                              NSDictionary *attributes) noexcept;
    BugsnagPerformanceSpan *startViewLoadPhaseSpan(NSString *className,
                                                   BugsnagPerformanceSpanContext *parentContext,
                                                   NSString *phase,
                                                   NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept;
    BugsnagPerformanceSpan *startLoadingIndicatorSpan(NSString *name,
                                                      BugsnagPerformanceSpanContext *parentContext) noexcept;
    
    void setup(ViewLoadSpanFactoryCallbacks *callbacks) noexcept { callbacks_ = callbacks; }
    
private:
    std::shared_ptr<PlainSpanFactory> plainSpanFactory_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    ViewLoadSpanFactoryCallbacks *callbacks_;
    
    BugsnagPerformanceSpan *startViewLoadPhaseSpan(UIViewController *viewController,
                                                   BugsnagPerformanceSpanContext *parentContext,
                                                   NSString *phase) noexcept;
    BugsnagPerformanceSpan *startViewLoadPhaseSpan(UIViewController *viewController,
                                                   BugsnagPerformanceSpanContext *parentContext,
                                                   NSString *phase,
                                                   NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept;
    
    ViewLoadSpanFactoryImpl() = delete;
};
}
