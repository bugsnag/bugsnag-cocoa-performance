//
//  ViewLoadSpanFactoryImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadSpanFactory.h"
#import "../../../SpanAttributesProvider.h"
#import "../../../Tracer.h"


namespace bugsnag {

class ViewLoadSpanFactoryImpl: public ViewLoadSpanFactory {
public:
    ViewLoadSpanFactoryImpl(std::shared_ptr<Tracer> tracer,
                            std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) noexcept
    : tracer_(tracer)
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
    
private:
    std::shared_ptr<Tracer> tracer_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    
    BugsnagPerformanceSpan *startViewLoadPhaseSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext, NSString *phase) noexcept;
    
    ViewLoadSpanFactoryImpl() = delete;
};
}
