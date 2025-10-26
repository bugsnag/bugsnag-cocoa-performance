//
//  Instrumentation.m
//  BugsnagPerformance-iOS
//
//  Created by Karl Stenerud on 24.04.23.
//  Copyright © 2023 Bugsnag. All rights reserved.
//

#import "Instrumentation.h"

#import "../Core/SpanFactory/Network/NetworkSpanFactoryImpl.h"
#import "../Core/SpanFactory/ViewLoad/ViewLoadSpanFactoryImpl.h"
#import "ViewLoadInstrumentation/System/ViewLoadInstrumentationSystemUtilsImpl.h"
#import "ViewLoadInstrumentation/System/ViewLoadSwizzlingHandlerImpl.h"
#import "ViewLoadInstrumentation/State/ViewLoadInstrumentationStateRepositoryImpl.h"
#import "ViewLoadInstrumentation/Lifecycle/ViewLoadLifecycleHandlerImpl.h"
#import "ViewLoadInstrumentation/Lifecycle/ViewLoadEarlyPhaseHandlerImpl.h"
#import "ViewLoadInstrumentation/Lifecycle/ViewLoadLoadingIndicatorsHandlerImpl.h"
#import "NetworkInstrumentation/State/NetworkInstrumentationStateRepositoryImpl.h"
#import "NetworkInstrumentation/System/BSGURLSessionPerformanceDelegate.h"
#import "NetworkInstrumentation/System/NetworkInstrumentationSystemUtilsImpl.h"
#import "NetworkInstrumentation/System/NetworkSwizzlingHandlerImpl.h"
#import "NetworkInstrumentation/Lifecycle/NetworkEarlyPhaseHandlerImpl.h"
#import "NetworkInstrumentation/Lifecycle/NetworkLifecycleHandlerImpl.h"

// App start spans will be thrown out if the early app start duration exceeds this.
static constexpr CFTimeInterval maxAppStartDuration = 2.0;

// App start spans will be thrown out if the app gets backgrounded within this timeframe after starting.
static constexpr CFTimeInterval minTimeToBackgrounding = 2.0;

using namespace bugsnag;

#pragma mark PhasedStartup

void Instrumentation::start() noexcept {
    checkAppStartDuration();
}

#pragma mark AppLifecycleListener

void
Instrumentation::onAppFinishedLaunching() noexcept {
    checkAppStartDuration();
}

void
Instrumentation::onAppEnteredBackground() noexcept {
    // We run this WITHOUT checking isStarted (in case there's notification
    // timing jank and we get the notification before we've started).
    if (appStartupInstrumentation_->timeSinceAppFirstBecameActive() < minTimeToBackgrounding) {
        // If we get backgrounded too quickly after app start, throw out
        // all app start spans even if they've completed.
        // Sometimes the jank between backgrounding/foregrounding events
        // can cause the spans to close very late, so we play it safe.
        appStartupInstrumentation_->abortAllSpans();
    }
}

#pragma mark Private

// This is checked in two places: Bugsnag start, and NSApplicationDidFinishLaunchingNotification.
void
Instrumentation::checkAppStartDuration() noexcept {
    if (!hasCheckedAppStartDuration_) {
        hasCheckedAppStartDuration_ = true;
        if (appStartupInstrumentation_->appStartDuration() > maxAppStartDuration) {
            appStartupInstrumentation_->abortAllSpans();
        }
    }
}
