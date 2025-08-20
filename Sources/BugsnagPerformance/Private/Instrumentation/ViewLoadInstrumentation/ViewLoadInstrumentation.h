//
//  ViewLoadInstrumentation.h
//  BugsnagPerformance
//
//  Created by Nick Dowell on 10/10/2022.
//

#import <UIKit/UIKit.h>
#import "../../PhasedStartup.h"
#import "../../Tracer.h"
#import "State/ViewLoadInstrumentationState.h"
#import "SpanFactory/ViewLoadSpanFactory.h"
#import "System/ViewLoadInstrumentationSystemUtils.h"
#import "System/ViewLoadSwizzlingHandler.h"

#import <vector>

NS_ASSUME_NONNULL_BEGIN

namespace bugsnag {
class ViewLoadInstrumentation: public PhasedStartup {
public:
    ViewLoadInstrumentation(std::shared_ptr<Tracer> tracer,
                            std::shared_ptr<SpanAttributesProvider> spanAttributesProvider,
                            std::shared_ptr<ViewLoadSpanFactory> spanFactory,
                            std::shared_ptr<ViewLoadInstrumentationSystemUtils> systemUtils,
                            std::shared_ptr<ViewLoadSwizzlingHandler> swizzlingHandler) noexcept
    : isEnabled_(true)
    , isEarlySpanPhase_(true)
    , tracer_(tracer)
    , spanAttributesProvider_(spanAttributesProvider)
    , spanFactory_(spanFactory)
    , systemUtils_(systemUtils)
    , swizzlingHandler_(swizzlingHandler)
    , earlySpans_([NSMutableArray new])
    {}

    void earlyConfigure(BSGEarlyConfiguration *config) noexcept;
    void earlySetup() noexcept;
    void configure(BugsnagPerformanceConfiguration *config) noexcept;
    void preStartSetup() noexcept {};
    void start() noexcept {}
    
private:
    void onLoadView(UIViewController *viewController) noexcept;
    void onViewDidAppear(UIViewController *viewController) noexcept;
    void onViewWillDisappear(UIViewController *viewController) noexcept;
    void endOverallSpan(UIViewController *viewController) noexcept;
    void endViewAppearingSpan(ViewLoadInstrumentationState *instrumentationState, CFAbsoluteTime atTime) noexcept;
    void endSubviewsLayoutSpan(UIViewController *viewController) noexcept;
    
    ViewLoadSwizzlingCallbacks *createViewLoadSwizzlingCallbacks() noexcept;

    static void setInstrumentationState(UIViewController *viewController, ViewLoadInstrumentationState * _Nullable state) noexcept;
    static ViewLoadInstrumentationState *getInstrumentationState(UIViewController *viewController) noexcept;

    void markEarlySpan(BugsnagPerformanceSpan *span) noexcept;
    void endEarlySpanPhase() noexcept;
    bool canCreateSpans(UIViewController *viewController) noexcept;
    void adjustSpanIfPreloaded(BugsnagPerformanceSpan *span, ViewLoadInstrumentationState *instrumentationState, NSDate *viewWillAppearStartTime, UIViewController *viewController) noexcept;
    NSString *nameForViewController(UIViewController *viewController) noexcept;

    bool isEnabled_{true};
    bool swizzleViewLoadPreMain_{true};
    std::shared_ptr<Tracer> tracer_;
    std::shared_ptr<ViewLoadSpanFactory> spanFactory_;
    std::shared_ptr<ViewLoadInstrumentationSystemUtils> systemUtils_;
    std::shared_ptr<ViewLoadSwizzlingHandler> swizzlingHandler_;
    BOOL (^ _Nullable callback_)(UIViewController *viewController){nullptr};
    std::shared_ptr<SpanAttributesProvider> spanAttributesProvider_;
    std::atomic<bool> isEarlySpanPhase_{true};
    std::recursive_mutex earlySpansMutex_;
    NSMutableArray<BugsnagPerformanceSpan *> * _Nullable earlySpans_;
};
}

NS_ASSUME_NONNULL_END
