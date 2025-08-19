//
//  AppStartupSpanFactoryImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 19/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "AppStartupSpanFactoryImpl.h"
#import "../../../Tracer.h"

AppStartupSpanFactoryImpl::AppStartupSpanFactoryImpl(std::shared_ptr<Tracer> tracer,
                                                     std::shared_ptr<SpanAttributesProvider> spanAttributesProvider) noexcept
: tracer_(tracer)
, spanAttributesProvider_(spanAttributesProvider) {}


BugsnagPerformanceSpan *
AppStartupSpanFactoryImpl::startAppStartSpan(CFAbsoluteTime startTime, bool isColdLaunch, NSString *firstViewName) noexcept {
    auto name = isColdLaunch ? @"[AppStart/iOSCold]" : @"[AppStart/iOSWarm]";
    SpanOptions options;
    options.startTime = startTime;
    BugsnagPerformanceSpan *appStartSpan = tracer_->startAppStartSpan(name, options, @[]);
    [appStartSpan internalSetMultipleAttributes:spanAttributesProvider_->appStartSpanAttributes(firstViewName, isColdLaunch)];
    return appStartSpan;
}

BugsnagPerformanceSpan *
AppStartupSpanFactoryImpl::startPreMainSpan(CFAbsoluteTime startTime, BugsnagPerformanceSpanContext *parentContext) noexcept {
    auto name = @"[AppStartPhase/App launching - pre main()]";
    SpanOptions options;
    options.startTime = startTime;
    options.parentContext = parentContext;
    BugsnagPerformanceSpan *preMainSpan = tracer_->startAppStartSpan(name, options, @[]);
    [preMainSpan internalSetMultipleAttributes:spanAttributesProvider_->appStartPhaseSpanAttributes(@"App launching - pre main()")];
    return preMainSpan;
}

BugsnagPerformanceSpan *
AppStartupSpanFactoryImpl::startPostMainSpan(CFAbsoluteTime startTime, BugsnagPerformanceSpanContext *parentContext) noexcept {
    auto name = @"[AppStartPhase/App launching - post main()]";
    SpanOptions options;
    options.startTime = startTime;
    options.parentContext = parentContext;
    BugsnagPerformanceSpan *postMainSpan = tracer_->startAppStartSpan(name, options, @[]);
    [postMainSpan internalSetMultipleAttributes:spanAttributesProvider_->appStartPhaseSpanAttributes(@"App launching - post main()")];
    return postMainSpan;
}

BugsnagPerformanceSpan *
AppStartupSpanFactoryImpl::startUIInitSpan(CFAbsoluteTime startTime,
                                           BugsnagPerformanceSpanContext *parentContext,
                                           NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept {
    auto name = @"[AppStartPhase/UI init]";
    SpanOptions options;
    options.startTime = startTime;
    options.parentContext = parentContext;
    BugsnagPerformanceSpan *uiInitSpan = tracer_->startAppStartSpan(name, options, conditionsToEndOnClose);
    [uiInitSpan internalSetMultipleAttributes:spanAttributesProvider_->appStartPhaseSpanAttributes(@"UI init")];
    return uiInitSpan;
}
