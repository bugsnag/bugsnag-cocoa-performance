//
//  ViewLoadSpanFactoryImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadSpanFactoryImpl.h"
#import "../../../Tracer.h"
#import "../../../BugsnagSwiftTools.h"

using namespace bugsnag;

ViewLoadSpanFactoryImpl::ViewLoadSpanFactoryImpl(std::shared_ptr<Tracer> tracer,
                                                 std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) noexcept
: tracer_(tracer)
, spanAttributesProvider_(spanAttributesProvider) {}

BugsnagPerformanceSpan *
ViewLoadSpanFactoryImpl::startOverallViewLoadSpan(UIViewController *viewController) noexcept {
    auto viewType = BugsnagPerformanceViewTypeUIKit;
    auto name = [BugsnagSwiftTools demangledClassNameFromInstance:viewController];
    SpanOptions options;
    auto span = tracer_->startViewLoadSpan(viewType, name, options);
    [span internalSetMultipleAttributes:spanAttributesProvider_->viewLoadSpanAttributes(name, viewType)];
    return span;
}

BugsnagPerformanceSpan *
ViewLoadSpanFactoryImpl::startPreloadedPresentingSpan(UIViewController *viewController) noexcept {
    auto viewType = BugsnagPerformanceViewTypeUIKit;
    auto className = [BugsnagSwiftTools demangledClassNameFromInstance:viewController];
    
    SpanOptions options;
    auto span = tracer_->startViewLoadSpan(viewType, className, options);
    [span internalSetMultipleAttributes:spanAttributesProvider_->presentingViewLoadSpanAttributes(className, viewType)];
    [span updateName: [NSString stringWithFormat:@"%@ (presenting)", span.name]];
    return span;
}

BugsnagPerformanceSpan *
ViewLoadSpanFactoryImpl::startLoadViewSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept {
    return startViewLoadPhaseSpan(viewController, parentContext, @"loadView");
}

BugsnagPerformanceSpan *
ViewLoadSpanFactoryImpl::startViewDidLoadSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept {
    return startViewLoadPhaseSpan(viewController, parentContext, @"viewDidLoad");
}

BugsnagPerformanceSpan *
ViewLoadSpanFactoryImpl::startViewWillAppearSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept {
    return startViewLoadPhaseSpan(viewController, parentContext, @"viewWillAppear");
}

BugsnagPerformanceSpan *
ViewLoadSpanFactoryImpl::startViewAppearingSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept {
    return startViewLoadPhaseSpan(viewController, parentContext, @"View appearing");
}

BugsnagPerformanceSpan *
ViewLoadSpanFactoryImpl::startViewDidAppearSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept {
    return startViewLoadPhaseSpan(viewController, parentContext, @"viewDidAppear");
}

BugsnagPerformanceSpan *
ViewLoadSpanFactoryImpl::startViewWillLayoutSubviewsSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept {
    return startViewLoadPhaseSpan(viewController, parentContext, @"viewWillLayoutSubviews");
}

BugsnagPerformanceSpan *
ViewLoadSpanFactoryImpl::startSubviewsLayoutSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept {
    return startViewLoadPhaseSpan(viewController, parentContext, @"Subview layout");
}

BugsnagPerformanceSpan *
ViewLoadSpanFactoryImpl::startViewDidLayoutSubviewsSpan(UIViewController *viewController, BugsnagPerformanceSpanContext *parentContext) noexcept {
    return startViewLoadPhaseSpan(viewController, parentContext, @"viewDidLayoutSubviews");
}

BugsnagPerformanceSpan *
ViewLoadSpanFactoryImpl::startLoadingSpan(UIViewController *viewController,
                                          BugsnagPerformanceSpanContext *parentContext,
                                          NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept {
    return startViewLoadPhaseSpan(viewController,
                                  parentContext,
                                  @"viewDataLoading",
                                  conditionsToEndOnClose);
}

#pragma mark Helpers

BugsnagPerformanceSpan *
ViewLoadSpanFactoryImpl::startViewLoadPhaseSpan(UIViewController *viewController,
                                                BugsnagPerformanceSpanContext *parentContext,
                                                NSString *phase) noexcept {
    return startViewLoadPhaseSpan(viewController, parentContext, phase, @[]);
}

BugsnagPerformanceSpan *
ViewLoadSpanFactoryImpl::startViewLoadPhaseSpan(UIViewController *viewController,
                                                BugsnagPerformanceSpanContext *parentContext,
                                                NSString *phase,
                                                NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept {
    auto name = [BugsnagSwiftTools demangledClassNameFromInstance:viewController];
    auto span = tracer_->startViewLoadPhaseSpan(name,
                                                phase,
                                                parentContext,
                                                conditionsToEndOnClose);
    [span internalSetMultipleAttributes:spanAttributesProvider_->viewLoadPhaseSpanAttributes(name, phase)];
    return span;
}
