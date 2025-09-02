//
//  AppStartupSpanFactoryImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 19/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "AppStartupSpanFactoryImpl.h"
#import "../../Tracer.h"

static NSString *const PreMainPhaseName = @"App launching - pre main()";
static NSString *const PostMainPhaseName = @"App launching - post main()";
static NSString *const UIInitPhaseName = @"UI init";

using namespace bugsnag;

BugsnagPerformanceSpan *
AppStartupSpanFactoryImpl::startAppStartOverallSpan(CFAbsoluteTime startTime, bool isColdLaunch, NSString *firstViewName) noexcept {
    NSLog(@"DARIA_LOG AppStartupSpanFactoryImpl::startAppStartOverallSpan");
    auto name = isColdLaunch ? @"[AppStart/iOSCold]" : @"[AppStart/iOSWarm]";
    SpanOptions options;
    options.startTime = startTime;
    auto attributes = spanAttributesProvider_->appStartSpanAttributes(firstViewName, isColdLaunch);
    NSLog(@"DARIA_LOG AppStartupSpanFactoryImpl::startAppStartOverallSpan created");
    return startAppStartSpan(name, options, attributes, @[]);
}

BugsnagPerformanceSpan *
AppStartupSpanFactoryImpl::startPreMainSpan(CFAbsoluteTime startTime, BugsnagPerformanceSpanContext *parentContext) noexcept {
    return startAppStartPhaseSpan(PreMainPhaseName,
                                  startTime,
                                  parentContext,
                                  @[]);
}

BugsnagPerformanceSpan *
AppStartupSpanFactoryImpl::startPostMainSpan(CFAbsoluteTime startTime, BugsnagPerformanceSpanContext *parentContext) noexcept {
    return startAppStartPhaseSpan(PostMainPhaseName,
                                  startTime,
                                  parentContext,
                                  @[]);
}

BugsnagPerformanceSpan *
AppStartupSpanFactoryImpl::startUIInitSpan(CFAbsoluteTime startTime,
                                           BugsnagPerformanceSpanContext *parentContext,
                                           NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept {
    return startAppStartPhaseSpan(UIInitPhaseName,
                                  startTime,
                                  parentContext,
                                  conditionsToEndOnClose);
}

BugsnagPerformanceSpan *
AppStartupSpanFactoryImpl::startAppStartSpan(NSString *name,
                                             const SpanOptions &options,
                                             NSDictionary *attributes,
                                             NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept {
    auto spanAttributes = spanAttributesProvider_->initialAppStartSpanAttributes();
    [spanAttributes addEntriesFromDictionary:attributes];
    return plainSpanFactory_->startSpan(name,
                                        options,
                                        BSGTriStateUnset,
                                        spanAttributes,
                                        conditionsToEndOnClose);
}

#pragma mark Helpers

BugsnagPerformanceSpan *
AppStartupSpanFactoryImpl::startAppStartPhaseSpan(NSString *phase,
                                                  CFAbsoluteTime startTime,
                                                  BugsnagPerformanceSpanContext *parentContext,
                                                  NSArray<BugsnagPerformanceSpanCondition *> *conditionsToEndOnClose) noexcept {
    auto name = [NSString stringWithFormat:@"[AppStartPhase/%@]", phase];
    SpanOptions options;
    options.startTime = startTime;
    options.parentContext = parentContext;
    auto attributes = spanAttributesProvider_->appStartPhaseSpanAttributes(phase);
    return startAppStartSpan(name, options, attributes, conditionsToEndOnClose);
}
                           
