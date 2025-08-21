//
//  ViewLoadLifecycleHandlerImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 21/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadLifecycleHandler.h"
#import "../SpanFactory/ViewLoadSpanFactory.h"
#import "../../../Tracer.h"
#import "../../../BugsnagPerformanceCrossTalkAPI.h"

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

class ViewLoadLifecycleHandlerImpl: public ViewLoadLifecycleHandler {
public:
    ViewLoadLifecycleHandlerImpl(std::shared_ptr<Tracer> tracer,
                                 std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                                 std::shared_ptr<ViewLoadSpanFactory> spanFactory,
                                 BugsnagPerformanceCrossTalkAPI *crosstalkAPI) noexcept;
    
    void onInstrumentationConfigured(bool isEnabled, __nullable BugsnagPerformanceViewControllerInstrumentationCallback callback) noexcept;
    void onLoadView(ViewLoadInstrumentationState *state,
                            UIViewController *viewController,
                            ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept;
    void onViewDidLoad(ViewLoadInstrumentationState *state,
                               UIViewController *viewController,
                               ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept;
    void onViewWillAppear(ViewLoadInstrumentationState *state,
                                  UIViewController *viewController,
                                  ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept;
    void onViewDidAppear(ViewLoadInstrumentationState *state,
                                 UIViewController *viewController,
                                 ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept;
    void onViewWillLayoutSubviews(ViewLoadInstrumentationState *state,
                                          UIViewController *viewController,
                                          ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept;
    void onViewDidLayoutSubviews(ViewLoadInstrumentationState *state,
                                         UIViewController *viewController,
                                         ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept;
    
private:
    std::shared_ptr<Tracer> tracer_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    std::shared_ptr<ViewLoadSpanFactory> spanFactory_;
    BugsnagPerformanceCrossTalkAPI *crosstalkAPI_;
    
    std::recursive_mutex earlyPhaseMutex_;
    std::atomic<bool> isEarlyPhase_{true};
    NSMutableArray<ViewLoadInstrumentationState *> * _Nullable earlyStates_;
    
    std::mutex spanMutex_;
    
    void markEarlyStateIfNeeded(ViewLoadInstrumentationState *state) noexcept;
    void markEarlyState(ViewLoadInstrumentationState *state) noexcept;
    void endEarlyPhase(bool isEnabled, __nullable BugsnagPerformanceViewControllerInstrumentationCallback callback) noexcept;
    
    void endOverallSpan(ViewLoadInstrumentationState *state, UIViewController *viewController) noexcept;
    void endViewAppearingSpan(ViewLoadInstrumentationState *state, CFAbsoluteTime atTime) noexcept;
    void endSubviewsLayoutSpan(ViewLoadInstrumentationState *state) noexcept;
    
    void adjustSpanIfPreloaded(BugsnagPerformanceSpan *span, ViewLoadInstrumentationState *state, NSDate *viewWillAppearStartTime, UIViewController *viewController) noexcept;
    
    ViewLoadLifecycleHandlerImpl() = delete;
};
}

NS_ASSUME_NONNULL_END
