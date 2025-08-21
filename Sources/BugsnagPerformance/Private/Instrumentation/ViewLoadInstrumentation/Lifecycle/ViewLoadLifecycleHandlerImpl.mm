//
//  ViewLoadLifecycleHandlerImpl.mm
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 21/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadLifecycleHandlerImpl.h"

#import "../../../BugsnagSwiftTools.h"

using namespace bugsnag;

static constexpr CGFloat kViewWillAppearPreloadedDelayThreshold = 1.0;

ViewLoadLifecycleHandlerImpl::ViewLoadLifecycleHandlerImpl(std::shared_ptr<Tracer> tracer,
                                                           std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                                                           std::shared_ptr<ViewLoadSpanFactory> spanFactory,
                                                           BugsnagPerformanceCrossTalkAPI *crosstalkAPI) noexcept
: tracer_(tracer)
, spanAttributesProvider_(spanAttributesProvider)
, spanFactory_(spanFactory)
, crosstalkAPI_(crosstalkAPI)
, isEarlyPhase_(true)
, earlyStates_([NSMutableArray new]) {}

#pragma mark Lifecycle

void
ViewLoadLifecycleHandlerImpl::onInstrumentationConfigured(bool isEnabled, __nullable BugsnagPerformanceViewControllerInstrumentationCallback callback) noexcept {
    endEarlyPhase(isEnabled, callback);
}

void
ViewLoadLifecycleHandlerImpl::onLoadView(ViewLoadInstrumentationState *state,
                                         UIViewController *viewController,
                                         ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept {
    if (state.loadViewSpan != nil) {
        originalImplementation();
        return;
    }
    markEarlyStateIfNeeded(state);
    state.overallSpan = spanFactory_->startOverallViewLoadSpan(viewController);
    
    state.loadViewSpan = spanFactory_->startLoadViewSpan(viewController,
                                                         state.overallSpan);
    originalImplementation();
    [state.loadViewSpan end];
}

void
ViewLoadLifecycleHandlerImpl::onViewDidLoad(ViewLoadInstrumentationState *state,
                                            UIViewController *viewController,
                                            ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept {
    if (state.overallSpan == nil || state.viewDidLoadSpan != nil) {
        originalImplementation();
        return;
    }
    
    state.viewDidLoadSpan = spanFactory_->startViewDidLoadSpan(viewController,
                                                               state.overallSpan);
    originalImplementation();
    [state.viewDidLoadSpan end];
}

void
ViewLoadLifecycleHandlerImpl::onViewWillAppear(ViewLoadInstrumentationState *state,
                                               UIViewController *viewController,
                                               ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept {
    BugsnagPerformanceSpan *overallSpan = state.overallSpan;
    if (overallSpan == nil || state.viewWillAppearSpan != nil) {
        originalImplementation();
        return;
    }
    adjustSpanIfPreloaded(overallSpan, state, [NSDate new], viewController);
    state.viewWillAppearSpan = spanFactory_->startViewWillAppearSpan(viewController,
                                                                     state.overallSpan);
    originalImplementation();
    [state.viewWillAppearSpan end];
    state.viewAppearingSpan = spanFactory_->startViewAppearingSpan(viewController,
                                                                   state.overallSpan);
}

void
ViewLoadLifecycleHandlerImpl::onViewDidAppear(ViewLoadInstrumentationState *state,
                                              UIViewController *viewController,
                                              ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept {
    if (state.overallSpan == nil || state.viewDidAppearSpan != nil) {
        originalImplementation();
        return;
    }
    endViewAppearingSpan(state, CFAbsoluteTimeGetCurrent());
    state.viewDidAppearSpan = spanFactory_->startViewDidAppearSpan(viewController,
                                                                   state.overallSpan);
    originalImplementation();
    [state.viewDidAppearSpan end];
    endOverallSpan(state, viewController);
}

void
ViewLoadLifecycleHandlerImpl::onViewWillLayoutSubviews(ViewLoadInstrumentationState *state,
                                                       UIViewController *viewController,
                                                       ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept {
    if (state.overallSpan == nil || state.viewWillLayoutSubviewsSpan != nil) {
        originalImplementation();
        return;
    }
    state.viewWillLayoutSubviewsSpan = spanFactory_->startViewWillLayoutSubviewsSpan(viewController,
                                                                                     state.overallSpan);
    originalImplementation();
    [state.viewWillLayoutSubviewsSpan end];
    state.subviewLayoutSpan = spanFactory_->startSubviewsLayoutSpan(viewController,
                                                                    state.overallSpan);
}

void
ViewLoadLifecycleHandlerImpl::onViewDidLayoutSubviews(ViewLoadInstrumentationState *state,
                                                      UIViewController *viewController,
                                                      ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept {
    if (state.overallSpan == nil || state.viewDidLayoutSubviewsSpan != nil) {
        originalImplementation();
        return;
    }
    endSubviewsLayoutSpan(state);
    state.viewDidLayoutSubviewsSpan = spanFactory_->startViewDidLayoutSubviewsSpan(viewController,
                                                                                   state.overallSpan);
    originalImplementation();
    [state.viewDidLayoutSubviewsSpan end];
    auto subviewsDidLayoutAtTime = CFAbsoluteTimeGetCurrent();
    
    void (^endViewAppearingSpanIfNeeded)(ViewLoadInstrumentationState *) = ^void(ViewLoadInstrumentationState *s) {
        auto overallSpan = s.overallSpan;
        if (overallSpan.state == SpanStateOpen) {
            [overallSpan endWithAbsoluteTime:subviewsDidLayoutAtTime];
        }
        endViewAppearingSpan(s, subviewsDidLayoutAtTime);
    };
    
    // If the overall span still hasn't ended when the ViewController is deallocated, use the time from viewDidLayoutSubviews
    state.onDealloc = endViewAppearingSpanIfNeeded;
    
    __block __weak UIViewController *weakViewController = viewController;
    __block __weak ViewLoadInstrumentationState *weakState = state;
    // If the overall span still hasn't ended after 10 seconds, use the time from viewDidLayoutSubviews
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong UIViewController *strongViewController = weakViewController;
        __strong ViewLoadInstrumentationState *strongState = weakState;
        if (strongViewController == nil || strongState == nil) {
            return;
        }
        strongState.onDealloc = nil;
        endViewAppearingSpanIfNeeded(strongState);
    });
}

#pragma mark Helpers

void
ViewLoadLifecycleHandlerImpl::markEarlyStateIfNeeded(ViewLoadInstrumentationState *state) noexcept {
    if (isEarlyPhase_) {
        markEarlyState(state);
    }
}

void
ViewLoadLifecycleHandlerImpl::markEarlyState(ViewLoadInstrumentationState *state) noexcept {
    std::lock_guard<std::recursive_mutex> guard(earlyPhaseMutex_);
    [earlyStates_ addObject:state];
}

void
ViewLoadLifecycleHandlerImpl::endEarlyPhase(bool isEnabled, __nullable BugsnagPerformanceViewControllerInstrumentationCallback callback) noexcept {
    std::lock_guard<std::recursive_mutex> guard(earlyPhaseMutex_);
    BugsnagPerformanceViewControllerInstrumentationCallback vcCallback = callback;
    if (vcCallback == nullptr) {
        vcCallback = ^(UIViewController *){
            return YES;
        };
    }
    for (ViewLoadInstrumentationState *state: earlyStates_) {
        UIViewController *viewController = state.viewController;
        if (!isEnabled || (viewController != nil && !vcCallback(viewController))) {
            tracer_->cancelQueuedSpan(state.overallSpan);
            tracer_->cancelQueuedSpan(state.loadViewSpan);
            tracer_->cancelQueuedSpan(state.viewDidLoadSpan);
            tracer_->cancelQueuedSpan(state.viewWillAppearSpan);
            tracer_->cancelQueuedSpan(state.viewAppearingSpan);
            tracer_->cancelQueuedSpan(state.viewDidAppearSpan);
            tracer_->cancelQueuedSpan(state.viewWillLayoutSubviewsSpan);
            tracer_->cancelQueuedSpan(state.subviewLayoutSpan);
            tracer_->cancelQueuedSpan(state.viewDidLayoutSubviewsSpan);
        }
    }
    earlyStates_ = nil;
    isEarlyPhase_ = false;
}

void
ViewLoadLifecycleHandlerImpl::endOverallSpan(ViewLoadInstrumentationState *state, UIViewController *viewController) noexcept {
    std::lock_guard<std::mutex> guard(spanMutex_);
    if (state.overallSpan == nil || !state.overallSpan.isValid) {
        return;
    }
    BugsnagPerformanceSpan *overallSpan = state.overallSpan;
    [crosstalkAPI_ willEndViewLoadSpan:overallSpan viewController:viewController];

    [state.overallSpan end];
}

void
ViewLoadLifecycleHandlerImpl::endViewAppearingSpan(ViewLoadInstrumentationState *state, CFAbsoluteTime atTime) noexcept {
    std::lock_guard<std::mutex> guard(spanMutex_);
    if (!state.viewAppearingSpan.isValid) {
        return;
    }
    [state.viewAppearingSpan endWithAbsoluteTime:atTime];
}

void
ViewLoadLifecycleHandlerImpl::endSubviewsLayoutSpan(ViewLoadInstrumentationState *state) noexcept {
    std::lock_guard<std::mutex> guard(spanMutex_);
    if (!state.subviewLayoutSpan.isValid) {
        return;
    }
    [state.subviewLayoutSpan end];
}

void
ViewLoadLifecycleHandlerImpl::adjustSpanIfPreloaded(BugsnagPerformanceSpan *span, ViewLoadInstrumentationState *state, NSDate *viewWillAppearStartTime, UIViewController *viewController) noexcept {
    NSDate *viewDidLoadEndTime = [state.viewDidLoadSpan endTime];
    if (state.isMarkedAsPreloaded || viewDidLoadEndTime == nil) {
        return;
    }
    auto isPreloaded = [viewWillAppearStartTime timeIntervalSinceDate: viewDidLoadEndTime] > kViewWillAppearPreloadedDelayThreshold;
    if (isPreloaded) {
        auto viewType = BugsnagPerformanceViewTypeUIKit;
        auto className = [BugsnagSwiftTools demangledClassNameFromInstance:viewController];
        [span updateName: [NSString stringWithFormat:@"%@ (pre-load)", span.name]];
        [span internalSetMultipleAttributes:spanAttributesProvider_->preloadViewLoadSpanAttributes(className, viewType)];
        state.isMarkedAsPreloaded = true;
        [span endWithEndTime:viewDidLoadEndTime];
        
        state.overallSpan = spanFactory_->startPreloadedPresentingSpan(viewController);
    }
}
