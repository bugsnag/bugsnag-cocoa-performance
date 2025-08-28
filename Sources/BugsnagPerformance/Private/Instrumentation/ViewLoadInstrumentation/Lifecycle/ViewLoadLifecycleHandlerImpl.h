//
//  ViewLoadLifecycleHandlerImpl.h
//  BugsnagPerformance
//
//  Created by Robert Bartoszewski on 21/08/2025.
//  Copyright © 2025 Bugsnag. All rights reserved.
//

#import "ViewLoadLifecycleHandler.h"
#import "ViewLoadEarlyPhaseHandler.h"
#import "../SpanFactory/ViewLoadSpanFactory.h"
#import "../State/ViewLoadInstrumentationStateRepository.h"
#import "../../../Tracer.h"
#import "../../../BugsnagPerformanceCrossTalkAPI.h"

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {

class ViewLoadLifecycleHandlerImpl: public ViewLoadLifecycleHandler {
public:
    ViewLoadLifecycleHandlerImpl(std::shared_ptr<ViewLoadEarlyPhaseHandler> earlyPhaseHandler,
                                 std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                                 std::shared_ptr<ViewLoadSpanFactory> spanFactory,
                                 std::shared_ptr<ViewLoadInstrumentationStateRepository> repository,
                                 BugsnagPerformanceCrossTalkAPI *crosstalkAPI) noexcept
    : earlyPhaseHandler_(earlyPhaseHandler)
    , spanAttributesProvider_(spanAttributesProvider)
    , spanFactory_(spanFactory)
    , repository_(repository)
    , crosstalkAPI_(crosstalkAPI) {}
    
    void onInstrumentationConfigured(bool isEnabled, __nullable BugsnagPerformanceViewControllerInstrumentationCallback callback) noexcept;
    void onLoadView(UIViewController *viewController,
                    ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept;
    void onViewDidLoad(UIViewController *viewController,
                       ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept;
    void onViewWillAppear(UIViewController *viewController,
                          ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept;
    void onViewDidAppear(UIViewController *viewController,
                         ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept;
    void onViewWillLayoutSubviews(UIViewController *viewController,
                                  ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept;
    void onViewDidLayoutSubviews(UIViewController *viewController,
                                 ViewLoadSwizzlingOriginalImplementationCallback originalImplementation) noexcept;
    
private:
    std::shared_ptr<ViewLoadEarlyPhaseHandler> earlyPhaseHandler_;
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    std::shared_ptr<ViewLoadSpanFactory> spanFactory_;
    std::shared_ptr<ViewLoadInstrumentationStateRepository> repository_;
    BugsnagPerformanceCrossTalkAPI *crosstalkAPI_;
    
    std::mutex spanMutex_;
    
    void endOverallSpan(ViewLoadInstrumentationState *state, UIViewController *viewController) noexcept;
    void endViewAppearingSpan(ViewLoadInstrumentationState *state, CFAbsoluteTime atTime) noexcept;
    void endSubviewsLayoutSpan(ViewLoadInstrumentationState *state) noexcept;
    
    void adjustSpanIfPreloaded(BugsnagPerformanceSpan *span, ViewLoadInstrumentationState *state, NSDate *viewWillAppearStartTime, UIViewController *viewController) noexcept;
    
    ViewLoadLifecycleHandlerImpl() = delete;
};
}

NS_ASSUME_NONNULL_END
