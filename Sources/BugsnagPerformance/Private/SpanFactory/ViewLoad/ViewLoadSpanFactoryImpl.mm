//
//  ViewLoadSpanFactoryImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 20/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadSpanFactoryImpl.h"
#import "../../Tracer.h"
#import "../../BugsnagSwiftTools.h"

using namespace bugsnag;

BugsnagPerformanceSpan *
ViewLoadSpanFactoryImpl::startOverallViewLoadSpan(UIViewController *viewController) noexcept {
    auto viewType = BugsnagPerformanceViewTypeUIKit;
    auto name = [BugsnagSwiftTools demangledClassNameFromInstance:viewController];
    SpanOptions options;
    return startViewLoadSpan(viewType, name, nil, options, @{});
}

BugsnagPerformanceSpan *
ViewLoadSpanFactoryImpl::startPreloadedPresentingSpan(UIViewController *viewController) noexcept {
    auto viewType = BugsnagPerformanceViewTypeUIKit;
    auto className = [BugsnagSwiftTools demangledClassNameFromInstance:viewController];
    
    SpanOptions options;
    auto attributes = spanAttributesProvider_->presentingViewLoadSpanAttributes(className, viewType);
    return startViewLoadSpan(viewType, className, @"(presenting)", options, attributes);
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

BugsnagPerformanceSpan *
ViewLoadSpanFactoryImpl::startViewLoadSpan(BugsnagPerformanceViewType viewType,
                                           NSString *className,
                                           NSString *suffix,
                                           const SpanOptions &options,
                                           NSDictionary *attributes) noexcept {
    NSString *type = getBugsnagPerformanceViewTypeName(viewType);
    NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose = @[];
    SpanOptions spanOptions(options);
    if (options.parentContext == nil && callbacks_.getViewLoadParentSpan != nil) {
        BugsnagPerformanceSpan *parentSpan = callbacks_.getViewLoadParentSpan();
        if (parentSpan != nil) {
            spanOptions.parentContext = parentSpan;
            BugsnagPerformanceSpanCondition *parentSpanCondition = [parentSpan blockWithTimeout:0.1];
            if (parentSpanCondition) {
                conditionsToEndOnClose = @[parentSpanCondition];
            }
        }
    }
    NSString *name = [NSString stringWithFormat:@"[ViewLoad/%@]/%@", type, className];
    if (suffix) {
        name = [NSString stringWithFormat:@"%@ %@", name, suffix];
    }
    if (options.firstClass == BSGTriStateUnset) {
        if (callbacks_.isViewLoadInProgress != nil && callbacks_.isViewLoadInProgress()) {
            spanOptions.firstClass = BSGTriStateNo;
        }
    }
    auto spanAttributes = spanAttributesProvider_->viewLoadSpanAttributes(className, viewType);
    [spanAttributes addEntriesFromDictionary:attributes];
    auto span = plainSpanFactory_->startSpan(name,
                                             spanOptions,
                                             BSGTriStateYes,
                                             spanAttributes,
                                             conditionsToEndOnClose);
    if (callbacks_.onViewLoadSpanStarted != nil) {
        callbacks_.onViewLoadSpanStarted(className);
    }
    return span;
}

BugsnagPerformanceSpan *
ViewLoadSpanFactoryImpl::startViewLoadPhaseSpan(NSString *className,
                                                BugsnagPerformanceSpanContext *parentContext,
                                                NSString *phase,
                                                NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept {
    auto attributes = spanAttributesProvider_->viewLoadPhaseSpanAttributes(className,
                                                                           phase);
    NSString *name = [NSString stringWithFormat:@"[ViewLoadPhase/%@]/%@", phase, className];
    SpanOptions options;
    options.parentContext = parentContext;
    auto span = plainSpanFactory_->startSpan(name,
                                             options,
                                             BSGTriStateUnset,
                                             attributes,
                                             conditionsToEndOnClose);
    return span;
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
    auto className = [BugsnagSwiftTools demangledClassNameFromInstance:viewController];
    return startViewLoadPhaseSpan(className, parentContext, phase, conditionsToEndOnClose);
}
